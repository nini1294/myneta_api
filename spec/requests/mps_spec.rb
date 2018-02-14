RSpec::Given.use_natural_assertions

RSpec.describe 'MyNeta mps' do
  include Rack::Test::Methods
  def app
    MyNeta
  end

  Then { app != nil }

  # Success cases

  context 'all mps' do

    When(:resp) { get '/mps' }
    Then { resp.status.eql? 200 }

    # Test the number of MPs
    When(:mps) { JSON.parse(resp.body) }
    Then { mps['count'].eql? 1576 }

    # Test a single MP
    When(:test_mp) { mps['mps'][1] }

  end

  context 'mps by year' do

    When(:resp) { get '/mps/2009' }
    Then { resp.status.eql? 200 }

    # Test the number of MPs
    When(:mps) { JSON.parse(resp.body) }
    Then { mps['count'].eql? 520 }

    # Test a single MP
    When(:test_mp) { mps['mps'][1] }

  end

  context 'mps by year and state' do
    When(:resp) { get '/mps/2004/maharashtra' }
    Then { resp.status.eql? 200 }

    # Test the number of MPs
    When(:mps) { JSON.parse(resp.body) }
    Then { mps['count'].eql? 44 }

    # Test a single MP
    When(:test_mp) { mps['mps'][1] }

  end

  # Failure cases
  context 'invalid year' do
    When(:resp) { get '/mps/2007' }
    Then { resp.status.eql? 400 }

    # Test the number of MPs
    When(:json) { JSON.parse(resp.body) }
    Then { json['valid_years'].eql? MyNeta::YEARS }

  end

  context 'invalid state' do
    When(:resp) { get '/mps/2014/mp' }
    Then { resp.status.eql? 400 }

    # Test the number of MPs
    When(:json) { JSON.parse(resp.body) }
    Then { json['valid_states'].eql? NetaScraper::MP_STATES }

  end

end
