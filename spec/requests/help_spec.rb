RSpec::Given.use_natural_assertions

RSpec.describe 'MyNeta help' do
  include Rack::Test::Methods
  def app
    MyNeta
  end

  Then { app != nil }

  # Root
  context 'main page' do

    When(:resp) { get '/' }
    Then { resp.status.eql? 200 }

    When(:json) { JSON.parse(resp.body) }

    When(:mps_example) { json['mps'] }
    Then { mps_example['endpoint'].eql? '/mps' }
    Then { mps_example['sample'].eql? '/mps[/year][/state or union_territory]' }

    When(:mlas_example) { json['mlas'] }
    Then { mlas_example['endpoint'].eql? '/mlas' }
    Then { mlas_example['sample'].eql? '/mlas[/state]' }

    Then { json['states'].eql? Constants::MLA_STATES }

  end

  context 'main page redirect' do
    # TODO
  end

end
