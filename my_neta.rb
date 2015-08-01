require 'roda'
require 'json'
require './neta_scraper'

class MyNeta < Roda

    YEARS = %w'2004 2009 2014'

    plugin :json
        
    route do |r|

        # Single initialization of the JSON object returned
        ret = {}

        # GET / request
        r.root do
            {
                :ok => 'breah',
                :mlas =>  MLA.limit(10).all.map{|mla| mla.format([:mla_id, :state, :assets])}
            }
        end

        # /scrape branch
        r.on 'scrape' do
            
            # Get all states
            r.is do
                neta_scraper_all()
            end

            # Get one state only
            r.get ':state' do |state|
                neta_scraper(state)
            end

            r.get 'check_db' do
                # hello_db
            end

        end

        # Route for getting MPs
        r.on 'mps' do
            
            r.is do
                ret[:count] = MP.count
                ret
            end

            r.on :year do |year|
                if YEARS.member?(year)
                    r.is do
                        ret[:count] = MP.filter(:year => year).count
                        ret
                    end
                    
                    r.get :state do |state|
                        if STATES.member?(state)
                            state = format_state(state)
                            ret[:count] = MP.filter(:year => year, :state => state).count
                        else
                            ret[:valid_states] = STATES
                        end
                        ret
                    end
                else
                    ret[:valid_years] = YEARS
                    ret
                end
            end
        end

        # Route for getting MLAs
        r.on 'mlas' do

            r.is do
                ret[:count] = MLA.count
                ret[:mlas] = MLA.map{|mla| mla.format}
                ret
            end
            
            r.get ':state' do |state|
                if STATES.member?(state)
                    formatted_state = format_state(state)
                    {
                        :state => formatted_state,
                        :count => MLA.filter(:state => formatted_state).count,
                        # Retrieve and format the required MLAs
                        :mlas => MLA.filter(:state => formatted_state).map{|mla| mla.format(%i'mla_id state')}
                    }
                else
                    {
                        :error => 'That is not a valid state'
                    }
                end
            end
        end

        # /message branch
        r.on 'message' do

            # /message?data
            r.is do
                {
                    'ok' => false,
                    'message' => r['data']
                }
            end
        end
    end
end