require 'nokogiri'
require 'open-uri'
require './models.rb'

STATES = [
  'andhra_pradesh', 'arunachal_pradesh', 'assam', 'bihar', 'chattisgarh',
  'delhi', 'goa', 'gujarat', 'haryana', 'himachal_pradesh', 'jammu_and_kashmir',
  'jharkhand', 'karnataka', 'kerala', 'madhya_pradesh', 'maharashtra',
  'manipur', 'meghalaya', 'mizoram', 'nagaland', 'odisha',
  'puducherry', 'punjab', 'rajasthan', 'sikkim', 'tamil_nadu',
  'telangana', 'tripura', 'uttarakhand', 'uttar_pradesh', 'west_bengal'
]

def neta_scraper(state)
    ret = {}
    if STATES.member?(state)
        begin
            mlas = get_mlas(state)
            ret[:state] = state
            ret[:mlas] = mlas
        rescue
            ret[:error] = 'You can\'t add duplicate MLAs'
        end
    else
        ret[:error] = 'That is not a valid state'
    end
    return ret
end

def neta_scraper_all()
    
    ret = {}
    arr = []

    STATES.each do |state|
        begin
            arr << get_mlas(state)
        rescue
            puts "#{format_state(state)} is already added"
        end
    end

    ret[:states] = arr

    return ret
end

def format_state(state)
    return state.capitalize.gsub(/_./) {|match| ' ' + match[1].capitalize;}
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

def get_mlas(state)
    election_url = get_election_url(state)
    page = Nokogiri::HTML(open(election_url))
    table = page.css('table').last
    mlas = table.css('tr').select do |x|
        # Select only the table rows containing data about the MLAs
        x.children.count.eql?(16)
    end
    ret = []
    instances = []
    mlas.each do |mla|
        elements = mla.children.select do |element|
            # Select only the table data and not the extra text
            element.is_a?(Nokogiri::XML::Element)
        end
        data = {}
        data[:state] = format_state(state)
        data[:name] = elements[1].text
        data[:constituency] = elements[2].text
        data[:party] = elements[3].text
        data[:criminal_cases] = elements[4].text.to_i
        data[:education] = elements[5].text
        money = elements[6].text
        # Format the money from a string to a Bignum
        money = money.split('~')[0].strip[3..-1].gsub(/,/, '').to_i
        data[:assets] = money
        ret << data
        instances << MLA.new(data)
    end
    MLA.multi_insert(instances)
    return ret
end
