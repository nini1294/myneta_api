require 'nokogiri'
require 'open-uri'
require './models.rb'

STATES = [
  'andhra_pradesh', 'arunachal_pradesh', 'assam', 'bihar', 'chattisgarh',
  'delhi', 'goa', 'gujarat', 'haryana', 'himachal_pradesh', 'jammu_and_kashmir',
  'jharkhand', 'karnataka', 'kerala', 'madhya_pradesh', 'maharashtra',
  'manipur', 'meghalaya', 'mizoram', 'nagaland', 'odisha',
  'puducherry', 'punjab', 'rajasthan', 'sikkim', 'tamil_nadu',
  'telangana', 'tripura', 'uttarakhand', 'uttar_pradesh', 'west_bengal',
]

def neta_scraper(state)
    ret = {}
    if STATES.member?(state)
        begin
            ret = get_mlas(state)
        rescue
            ret[:error] = 'You can\'t add duplicate MLAs'
        end
    elsif state.eql?('ls')
        get_mps()
    else
        ret[:error] = 'That is not a valid state'
    end
    return ret
end

def neta_scraper_all()
    
    ret = {}
    ret[:states] = []

    STATES.each do |state|
        begin
            ret[:states] << get_mlas(state)
        rescue
            puts "#{format_state(state)} is already added"
        end
    end

    return ret
end

def get_mlas(state)
    election_url = get_election_url(state)
    page = Nokogiri::HTML(open(election_url))
    table = page.css('table').last
    mlas = table.css('tr').select do |x|
        # Select only the table rows containing data about the MLAs
        x.children.count.eql?(16)
    end
    # Single instance of the formatted state
    formatted_state = format_state(state)
    ret = {}
    # Array containing all the MLAs from one state
    ret[formatted_state] = []
    instances = []
    mlas.each do |mla|
        elements = mla.children.select do |element|
            # Select only the table data and not the extra text
            element.is_a?(Nokogiri::XML::Element)
        end
        data = {}
        data[:name] = elements[1].text
        data[:constituency] = elements[2].text
        data[:party] = elements[3].text
        data[:criminal_cases] = elements[4].text.to_i
        data[:education] = elements[5].text
        money = elements[6].text
        # Format the money from a string to a Bignum
        money = money.split('~')[0].strip[3..-1].gsub(/,/, '').to_i
        data[:assets] = money
        data[:state] = formatted_state
        ret[formatted_state] << data
        instances << MLA.new(data)
    end
    MLA.multi_insert(instances)
    return ret
end

def format_state(state)
    state = state.capitalize.gsub(/(_| )./) {|match| ' ' + match[1].capitalize}
    return state.gsub(/&/, "And")
end

def get_election_url(state)
    # Format the state name
    formatted_state = format_state(state)
    url = "http://myneta.info/state_assembly.php?state=#{formatted_state}"
    url = URI.encode(url)
    url = URI.parse(url)
    page = Nokogiri::HTML(open(url))
    winners = page.css('a').select{|x| x.text.eql?('Winners')}
    winners.first.attributes["href"].value
end

def get_mps
    urls = get_mp_urls
    ret = {}
    urls.each do |url, year|
        instances = []
        ret[year] = []

        url = URI.parse(url)
        page = Nokogiri::HTML(open(url))
        table = page.css('table').last
        mps = table.css('tr').select do |x|
            # Select only the table rows containing data about the MPs
            x.children.count.eql?(16)
        end

        # Add data for each MP for each year
        mps.each do |mp|
            elements = mp.children.select do |element|
                # Select only the table data and not the extra text
                element.is_a?(Nokogiri::XML::Element)
            end
            data = {}
            data[:year] = year
            data[:name] = elements[1].text
            data[:constituency] = elements[2].text
            data[:party] = elements[3].text
            data[:criminal_cases] = elements[4].text.to_i
            data[:education] = elements[5].text
            money = elements[6].text
            # Format the money from a string to a Bignum
            money = money.split('~')[0].strip[3..-1].gsub(/,/, '').to_i
            data[:assets] = money
            # URL to page with details about the MP
            mp_url = mps.first.css('a').last.attributes.first[1].value
            data[:state] = mp_state(mp_url)
            ret[year] << data
            MP.new(data).save
        end
        # Insert rows
        # MP.multi_insert(instances)
    end
    return ret
end

def get_mp_urls
    url = URI.parse('http://myneta.info/')
    page = Nokogiri::HTML(open(url))
    urls = []
    years = []
    3.times do |x|
        anchor = page.xpath("//*[@id='main']/div/div[2]/div/div[1]/div[3]/div/div[#{x + 1}]/div/div/a[1]")
        urls << anchor.first['href']
        years << page.xpath("//*[@id='main']/div/div[2]/div/div[1]/div[3]/div/div[#{x + 1}]/div").text[/\d\d\d\d/]
    end
    return urls.zip(years)
end

# Helper function to get the state for a particular constituency
def mp_state(url)
    page = Nokogiri::HTML(open(url))
    # Text representing the state
    state_text = page.css('div > h5').first.children.text.strip
    # Removes the unnecessary text from the String
    state = state_text[/\(.+\)/][1..-2].downcase
    return format_state(state)
end
