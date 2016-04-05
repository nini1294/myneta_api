RSpec::Given.use_natural_assertions

RSpec.describe 'MyNeta mlas' do
  include Rack::Test::Methods
  def app
    MyNeta
  end

  Then { app != nil }

  # Success cases

  context 'all mlas' do

    When(:resp) { get '/mlas' }
    Then { resp.status.eql? 200 }

    # Test the number of MPs
    When(:mlas) { JSON.parse(resp.body) }
    Then { mlas['count'].eql? 4074 }

    # Test a single MLA
    When(:test_mla) { mlas['mlas'][1] }

  end

  context 'mlas by state' do

    When(:resp) { get '/mlas/bihar' }
    Then { resp.status.eql? 200 }

    # Test the number of MPs
    When(:mlas) { JSON.parse(resp.body) }
    Then { mlas['state'].eql? 'Bihar' }
    Then { mlas['count'].eql? 243 }

    # Test a single MLA
    When(:test_mla) { mlas['mlas'][1] }

  end

  # Failure cases
  context 'invalid state' do
    When(:resp) { get '/mlas/not' }
    Then { resp.status.eql? 400 }

    # Test the number of MPs
    When(:json) { JSON.parse(resp.body) }
    Then { json['error'].eql? 'That is not a valid state' }
    Then { json['valid_states'].eql? NetaScraper::MLA_STATES }

  end

end
