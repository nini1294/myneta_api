require 'roda'
require 'json'

class MyNeta < Roda

    plugin :json
    
    route do |r|
        # GET / request
        r.root do
            {
                'ok' => true
            }
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