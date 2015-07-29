require 'roda'
require 'json'
require './neta_scraper'

class MyNeta < Roda

    plugin :json
    plugin :default_headers, 'Content-Type'=>'application/json'
    
    route do |r|
        # GET / request
        r.root do
            {
                :ok => 'breah'
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

        r.on 'mlas' do

            r.is do
                ret = {}
                # ret[:states] = []
                # STATES.each do |state|
                    # formatted_state = format_state(state)
                    # ret[:states] << {
                        # :state => formatted_state,
                        # :count => MLA.filter(:state => formatted_state).count,
                        # # Retrieve and format the required MLAs
                        # :mlas => MLA.filter(:state => formatted_state).all
                    # }
                # end
                ret[:count] = MLA.count
                ret[:mlas] = format_mlas(MLA.all)
                ret
            end
            
            r.get ':state' do |state|
                if STATES.member?(state)
                    formatted_state = format_state(state)
                    {
                        :state => formatted_state,
                        :count => MLA.filter(:state => formatted_state).count,
                        # Retrieve and format the required MLAs
                        :mlas => format_mlas(MLA.filter(:state => formatted_state).all, [:mla_id, :state])
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

    # Helper formatting methods takes a parameter
    # specifying what to delete
    def format_mlas(arr, delete = [:mla_id])
        arr.map! do |mla|
            tmp = mla.to_hash
            delete.each do |param|
                tmp.delete(param)
            end
            tmp[:assets] = tmp[:assets].to_f
            tmp
        end
    end
end