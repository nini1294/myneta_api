require 'nokogiri'

STATES = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chattisgarh',
  'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu And Kashmir',
  'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
  'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
  'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttarakhand', 'Uttar Pradesh', 'West Bengal'
]

def neta_scraper(state)
    ret = {}
    if STATES.member?(state)
        arr = [state]
        ret[:state] = arr
    else
        ret[:error] = 'That is not a valid state'
    end
    return ret
end

def neta_scraper_all()
    
    ret = {}
    arr = []

    STATES.each do |state|
        arr << state;
    end

    ret[:states] = arr

    return ret
end
