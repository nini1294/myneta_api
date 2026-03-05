require 'nokogiri'
require 'open-uri'
require 'set'
require_relative '../models.rb'
require_relative './common/constants.rb'
require_relative './common/utils.rb'
require_relative './constituency_mapping.rb'

class NetaScraper
  # Cache constituency to state mappings to avoid repeated scraping
  @@constituency_state_cache = {}

  # Known URLs for Lok Sabha years
  KNOWN_MP_URLS = {
    '2024' => 'https://myneta.info/LokSabha2024/index.php?action=show_winners&sort=default',
    '2019' => 'https://myneta.info/LokSabha2019/index.php?action=show_winners&sort=default',
    '2014' => 'https://myneta.info/ls2014/index.php?action=show_winners&sort=default',
    '2009' => 'https://myneta.info/ls2009/index.php?action=show_winners&sort=default',
    '2004' => 'https://myneta.info/LokSabha2004/index.php?action=show_winners&sort=default'
  }.freeze

  class << self
    attr_accessor :constituency_state_cache
  end

  # Scrape MLAs by state (existing method, may need update)
  def self.scrape_mlas(state)
    ret = {}
    if Constants::MLA_STATES.member?(state)
      begin
        ret = get_mlas(state)
      rescue
        ret[:error] = "You can't add duplicate MLAs"
      end
    else
      ret[:error] = 'That is not a valid state'
    end
    ret
  end

  # Scrape all MLAs
  def self.scrape_all_mlas
    ret = {}
    ret[:states] = []

    Constants::MLA_STATES.each do |state|
      begin
        ret[:states] << get_mlas(state)
      rescue
        puts "#{Utils.format_state(state)} is already added"
      end
    end
    ret
  end

  # Get MLAs for a state (may need update for new site structure)
  def self.get_mlas(state)
    election_url = get_election_url(state)
    page = Nokogiri::HTML(URI.open(election_url))
    table = page.css('table').last
    mlas = table.css('tr').select do |x|
      # Select only the table rows containing data about the MLAs
      x.children.count.eql?(16)
    end
    formatted_state = Utils.format_state(state)
    ret = {}
    ret[formatted_state] = []
    instances = []
    mlas.each do |mla|
      elements = mla.children.select do |element|
        element.is_a?(Nokogiri::XML::Element)
      end
      data = {}
      data[:name] = elements[1].text
      data[:constituency] = elements[2].text
      data[:party] = elements[3].text
      data[:criminal_cases] = elements[4].text.to_i
      data[:education] = elements[5].text
      money = elements[6].text
      money = money.split('~')[0].strip[3..-1].gsub(/,/, '').to_i
      data[:assets] = money
      data[:state] = formatted_state
      ret[formatted_state] << data
      instances << MLA.new(data)
    end
    MLA.multi_insert(instances)
    ret
  end

  def self.get_election_url(state)
    formatted_state = Utils.format_state(state)
    url = "http://myneta.info/state_assembly.php?state=#{formatted_state}"
    url = URI.encode(url)
    url = URI.parse(url)
    page = Nokogiri::HTML(URI.open(url))
    winners = page.css('a').select { |x| x.text.eql?('Winners') }
    winners.first.attributes['href'].value
  end

  # UPDATED: Scrape MPs - uses new structure for 2024, old for earlier years
  def self.scrape_mps
    ret = {}

    KNOWN_MP_URLS.each do |year, url|
      puts "Scraping MPs for #{year}..."
      ret[year] = scrape_mp_year(year, url)
    end

    ret
  end

  # UPDATED: Scrape a specific year - handles both new (2024) and old structures
  def self.scrape_mp_year(year, url)
    puts "Scraping #{year} from #{url}"

    begin
      page = Nokogiri::HTML(URI.open(url))
      puts "  Page loaded, finding table..."
      table = find_winners_table(page, year)

      unless table
        puts "  Could not find winners table for #{year}"
        return []
      end

      puts "  Table found, scraping data..."
      # Determine structure based on year
      if year.to_i >= 2019
        # New structure: 8 columns
        scrape_mp_data_new_structure(year, table)
      else
        # Old structure: 16 columns
        scrape_mp_data_old_structure(year, table)
      end
    rescue => e
      puts "  Error scraping #{year}: #{e.message}"
      puts e.backtrace.first(3)
      []
    end
  end

  # Find the winners table in the page
  def self.find_winners_table(page, year)
    page.css('table').each_with_index do |table, table_idx|
      rows = table.css('tr')

      # Look for table with many candidate rows
      candidate_rows = rows.select do |r|
        children = r.children.select { |el| el.is_a?(Nokogiri::XML::Element) }
        # New structure: 8 columns, Old: 16 columns
        children.count >= 5 && children.count <= 20  # More flexible range
      end

      # Found the main data table - lower threshold
      if candidate_rows.count > 5
        # Check if this is a bye-election table (skip it)
        # More specific check - look for table headers indicating bye-elections
        header_text = table.css('tr:first').text.upcase

        # Check for bye-election indicators in header only
        is_bye_election = header_text.include?("BYE-ELECTION") ||
                          header_text.include?("BYE ELECTION") ||
                          (header_text.include?("BYE") && header_text.include?("ELECTION"))

        next if is_bye_election

        return table
      end
    end

    nil
  end

  # Scrape using NEW structure (2019+, 8 columns)
  def self.scrape_mp_data_new_structure(year, table)
    rows = table.css('tr')

    # More flexible row selection - expand column count range
    candidate_rows = rows.select do |r|
      children = r.children.select { |el| el.is_a?(Nokogiri::XML::Element) }
      children.count >= 5 && children.count <= 12  # Expanded range
    end

    mps_data = []
    unique_constituencies = Set.new
    skipped_rows = 0
    duplicate_count = 0

    candidate_rows.each do |row|
      children = row.children.select { |el| el.is_a?(Nokogiri::XML::Element) }

      # Skip header row - check multiple patterns
      first_text = children.first&.text&.to_s
      next if first_text.match?(/Sno|Serial|No\.|#/i)

      # Try to extract data based on column position
      data = {
        year: year,
        name: children[1]&.text&.strip,
        constituency: children[2]&.text&.strip,
        party: children[3]&.text&.strip,
        criminal_cases: extract_number(children[4]&.text),
        education: children[5]&.text&.strip,
        assets: extract_assets(children[6]&.text)
      }

      # Validate that we have minimal required data
      unless data[:name] && data[:name].length > 2
        skipped_rows += 1
        next
      end

      # Get candidate URL for state extraction
      candidate_link = children[1]&.css('a')&.last
      if candidate_link
        href = candidate_link['href']
        if href && href.start_with?('/')
          # Build full URL
          base_url = 'https://myneta.info'
          full_url = href.start_with?('http') ? href : "#{base_url}#{href}"

          # Extract state with caching
          constituency = data[:constituency]
          unless @@constituency_state_cache[constituency]
            state = mp_state_from_url(full_url, constituency)
            @@constituency_state_cache[constituency] = state if state
            sleep(0.5)  # Be nice to the server
          end
          data[:state_or_ut] = @@constituency_state_cache[constituency]
        end
      end

      # Fallback 1: Use constituency mapping
      data[:state_or_ut] ||= ConstituencyMapping.state_for_constituency(data[:constituency])

      # Fallback 2: try to infer state from constituency name
      data[:state_or_ut] ||= infer_state_from_constituency(data[:constituency])

      mps_data << data
      unique_constituencies << data[:constituency]

      # Save to database
      begin
        MP.new(data).save
        puts "  [#{mps_data.count}] #{data[:name]} (#{data[:constituency]}, #{data[:state_or_ut] || 'Unknown State'})"
      rescue Sequel::DatabaseError => e
        # Ignore duplicates
        duplicate_count += 1
        puts "  [DUP] #{data[:name]} (#{data[:constituency]})"
      end
    end

    puts "  Scraped #{mps_data.count} MPs for #{year} (#{unique_constituencies.count} unique constituencies, #{duplicate_count} duplicates, #{skipped_rows} skipped)"
    mps_data
  end

  # Scrape using OLD structure (pre-2019, 16 columns)
  def self.scrape_mp_data_old_structure(year, table)
    rows = table.css('tr')
    mps = rows.select { |x| x.children.count.eql?(16) }

    mps_data = []

    mps.each do |mp|
      elements = mp.children.select { |element| element.is_a?(Nokogiri::XML::Element) }
      data = {}
      data[:year] = year
      data[:name] = elements[1].text
      data[:constituency] = elements[2].text
      data[:party] = elements[3].text
      data[:criminal_cases] = elements[4].text.to_i
      data[:education] = elements[5].text
      money = elements[6].text
      money = money.split('~')[0].strip[3..-1].gsub(/,/, '').to_i
      data[:assets] = money

      mp_url = mp.css('a').last.attributes.first[1].value
      data[:state_or_ut] = mp_state_from_url(mp_url, data[:constituency])

      mps_data << data
      MP.new(data).save
    end

    puts "  Scraped #{mps_data.count} MPs for #{year}"
    mps_data
  end

  # UPDATED: Extract state from candidate page
  def self.mp_state_from_url(url, fallback_constituency = nil)
    begin
      page = Nokogiri::HTML(URI.open(url))

      # Method 1: From title (newer pages)
      title = page.css('title').text
      if title =~ /\(([^)]+)\)\s*-\s*Affidavit/i
        potential_state = $1.strip
        # Check if it's a state name
        if potential_state.match?(/^[A-Z\s]+$/) && potential_state.length < 30
          return Utils.format_state(potential_state.downcase)
        end
      end

      # Method 2: From div > h5 (older pages)
      state_div = page.css('div > h5')
      if state_div.any?
        state_text = state_div.first.children.text.strip
        # Extract state from parentheses - handles both "(STATE)" and "CONSTITUENCY  (STATE)" formats
        if state_text =~ /\(([^()]+)\)$/
          return Utils.format_state($1.downcase)
        elsif state_text =~ /\([^()]+\s*\([^()]+\)\)$/  # Double nested like "ADILABAD (ST)  (TELANGANA)"
          parts = state_text.scan(/\(([^()]+)\)/)
          return Utils.format_state(parts.last.first.downcase) if parts.any?
        end
      end

      # Fallback: try to infer from constituency name
      infer_state_from_constituency(fallback_constituency)
    rescue => e
      puts "Error extracting state from #{url}: #{e.message}"
      nil
    end
  end

  # Simple state inference from constituency name (fallback)
  def self.infer_state_from_constituency(constituency)
    return nil unless constituency

    # First try the comprehensive constituency mapping
    state = ConstituencyMapping.state_for_constituency(constituency)
    return state if state

    # Fallback to hardcoded prefix matching
    state_mappings = {
      'ADILABAD' => 'Telangana',
      'AGRA' => 'Uttar Pradesh',
      'AHMEDABAD' => 'Gujarat',
      'AJMER' => 'Rajasthan',
      'AKOLA' => 'Maharashtra',
      'ALIGARH' => 'Uttar Pradesh',
      'ALLAHABAD' => 'Uttar Pradesh',
      'AMRAVATI' => 'Maharashtra',
      'AMBALA' => 'Haryana',
      'AMETHI' => 'Uttar Pradesh',
      'AMRELI' => 'Gujarat',
      'ASANSOL' => 'West Bengal',
      'ATTINGAL' => 'Kerala',
      'BANGALORE' => 'Karnataka',
      'BAREILLY' => 'Uttar Pradesh',
      'BASTAR' => 'Chhattisgarh',
      'BEGUSARAI' => 'Bihar',
      'BELGAUM' => 'Karnataka',
      'BENGALURU' => 'Karnataka',
      'BHOPAL' => 'Madhya Pradesh',
      'BHUBANESWAR' => 'Odisha',
      'BIKANER' => 'Rajasthan',
      'BILASPUR' => 'Chhattisgarh',
      'BOKARO' => 'Jharkhand',
      'BUDAUN' => 'Uttar Pradesh',
      'CHANDIGARH' => 'Chandigarh',
      'CHENNAI' => 'Tamil Nadu',
      'COIMBATORE' => 'Tamil Nadu',
      'CUTTACK' => 'Odisha',
      'DARBHANGA' => 'Bihar',
      'DEHRADUN' => 'Uttarakhand',
      'DELHI' => 'Delhi',
      'DHANBAD' => 'Jharkhand',
      'DIBRUGARH' => 'Assam',
      'DURGAPUR' => 'West Bengal',
      'ERNAKULAM' => 'Kerala',
      'FAIZABAD' => 'Uttar Pradesh',
      'GAYA' => 'Bihar',
      'GHAZIABAD' => 'Uttar Pradesh',
      'GONDIA' => 'Maharashtra',
      'GORAKHPUR' => 'Uttar Pradesh',
      'GUWAHATI' => 'Assam',
      'GWALIOR' => 'Madhya Pradesh',
      'HUBLI' => 'Karnataka',
      'HYDERABAD' => 'Telangana',
      'IMPHAL' => 'Manipur',
      'INDORE' => 'Madhya Pradesh',
      'ITANAGAR' => 'Arunachal Pradesh',
      'JABALPUR' => 'Madhya Pradesh',
      'JAIPUR' => 'Rajasthan',
      'JALPAIGURI' => 'West Bengal',
      'JAMMU' => 'Jammu and Kashmir',
      'JAMSHEDPUR' => 'Jharkhand',
      'JHANSI' => 'Uttar Pradesh',
      'JODHPUR' => 'Rajasthan',
      'KANPUR' => 'Uttar Pradesh',
      'KARIMNAGAR' => 'Telangana',
      'KASHMIR' => 'Jammu and Kashmir',
      'KOLKATA' => 'West Bengal',
      'KOTA' => 'Rajasthan',
      'LUCKNOW' => 'Uttar Pradesh',
      'LUDHIANA' => 'Punjab',
      'MADURAI' => 'Tamil Nadu',
      'MANGALORE' => 'Karnataka',
      'MATHURA' => 'Uttar Pradesh',
      'MEERUT' => 'Uttar Pradesh',
      'MIRZAPUR' => 'Uttar Pradesh',
      'MORADABAD' => 'Uttar Pradesh',
      'MUMBAI' => 'Maharashtra',
      'MYSORE' => 'Karnataka',
      'NAGPUR' => 'Maharashtra',
      'NASIK' => 'Maharashtra',
      'NAVI MUMBAI' => 'Maharashtra',
      'NOIDA' => 'Uttar Pradesh',
      'PATNA' => 'Bihar',
      'PUNE' => 'Maharashtra',
      'RAIPUR' => 'Chhattisgarh',
      'RAJKOT' => 'Gujarat',
      'RANCHI' => 'Jharkhand',
      'SAHARANPUR' => 'Uttar Pradesh',
      'SHILLONG' => 'Meghalaya',
      'SHIMLA' => 'Himachal Pradesh',
      'SILCHAR' => 'Assam',
      'SILIGURI' => 'West Bengal',
      'SRINAGAR' => 'Jammu and Kashmir',
      'SURAT' => 'Gujarat',
      'THIRUVANANTHAPURAM' => 'Kerala',
      'TIRUPATI' => 'Andhra Pradesh',
      'TRICHY' => 'Tamil Nadu',
      'TRIVANDRUM' => 'Kerala',
      'VARANASI' => 'Uttar Pradesh',
      'VIJAYAWADA' => 'Andhra Pradesh',
      'VISHAKHAPATNAM' => 'Andhra Pradesh',
      'WARANGAL' => 'Telangana'
    }

    constituency_upcase = constituency.upcase
    state_mappings.each do |prefix, state|
      return state if constituency_upcase.include?(prefix)
    end

    nil
  end

  # Helper: Extract number from string (handles "1", "0", etc.)
  def self.extract_number(text)
    return 0 unless text
    text.to_s.strip.to_i
  rescue
    0
  end

  # Helper: Extract assets from string like "Rs 3,09,16,833 ~ 3 Crore+"
  def self.extract_assets(text)
    return nil unless text

    # Try to extract the numeric part before "~"
    if text =~ /Rs\s*([\d,]+)/i
      return $1.gsub(/,/, '').to_i
    end

    # Handle case where assets might be an image
    if text.include?('image_v2.php')
      return nil  # Can't extract from image
    end

    nil
  rescue
    nil
  end

  def self.mp_urls
    # Returns known URLs for all years
    KNOWN_MP_URLS
  end

  def self.hi
    puts 'Hi'
    'Hi'
  end
end
