require 'roda'
require 'json'
require 'dotenv'
Dotenv.load

require_relative './models.rb'
require_relative 'lib/common/constants.rb'
require_relative 'lib/common/utils.rb'

# Main app class
class MyNeta < Roda
    # All possible years for MPs
    YEARS = %w(2004 2009 2014 2019)

    plugin :json, serializer: proc { |o| JSON.pretty_generate(o) }

    route do |r|
        # Single initialization of the JSON object returned
        ret = {}

        # GET / request
        r.root do
            # Show endpoint examples
            {
                mps: {
                    endpoint: '/mps',
                    sample: '/mps[/year][/state or union_territory]',
                    examples: %W(/mps/#{YEARS.sample} /mps/2014/#{Constants::MP_STATES.sample})
                },
                mlas: {
                    endpoint: '/mlas',
                    sample: '/mlas[/state]',
                    examples: %W(/mlas /mlas/maharashtra /mlas/#{(Constants::MLA_STATES - %w(maharashtra)).sample})
                },
                states: Constants::MLA_STATES,
                union_territories: Constants::MP_STATES - Constants::MLA_STATES
            }
        end

        # # /scrape branch
        # r.on 'scrape' do
        #     # Get all states
        #     r.is do
        #         NetaScraper.scrape_all_mlas
        #     end

        #     # Get one state only
        #     r.get ':state' do |state|
        #         NetaScraper.scrape_mlas(state)
        #     end
        # end

        # Route for getting MPs
        r.on 'mps' do
            r.is do
                ret[:count] = MP.count
                ret[:mps] = MP.order_by(:year, :state_or_ut).map(&:format)
                ret
            end

            r.on :year do |year|
                if YEARS.member?(year)
                    r.is do
                        ret[:count] = MP.filter(year: year).count
                        ret[:mps] = MP.filter(year: year).order_by(:state_or_ut, :constituency)
                                    .map { |mp| mp.format(%i(mp_id year)) }
                        ret
                    end

                    r.get :state do |state|
                        if Constants::MP_STATES.member?(state)
                            state = Utils.format_state(state)
                            ret[:count] = MP.filter(year: year, state_or_ut: state).count
                            ret[:mps] = MP.filter(year: year, state_or_ut: state).order_by(:constituency)
                                        .map { |mp| mp.format(%i(mp_id year state_or_ut)) }
                        else
                            response.status = 400
                            ret[:error] = 'That is not a valid state or UT'
                            ret[:valid_states] = Constants::MP_STATES
                        end
                        ret
                    end
                else
                    response.status = 400
                    ret[:error] = 'That is not a valid year'
                    ret[:valid_years] = YEARS
                    ret
                end
            end
        end

        # Route for getting MLAs
        r.on 'mlas' do
            r.is do
                ret[:count] = MLA.count
                ret[:mlas] = MLA.map(&:format)
                ret
            end

            r.get :state do |state|
                if Constants::MLA_STATES.member?(state)
                    formatted_state = Utils.format_state(state)
                    {
                        state: formatted_state,
                        count: MLA.filter(state: formatted_state).count,
                        # Retrieve and format the required MLAs
                        mlas: MLA.filter(state: formatted_state)
                          .map { |mla| mla.format(%i(mla_id state)) }
                    }
                else
                    response.status = 400
                    {
                        error: 'That is not a valid state',
                        valid_states: Constants::MLA_STATES
                    }
                end
            end
        end

        # Route for any other, redirects to root
        r.on :other do |other|
          r.redirect('/')
        end
    end
end
