RSpec::Given.use_natural_assertions

RSpec.describe 'NetaScraper simple' do
  it "will respond to hi" do
    expect(NetaScraper.hi).to eq('Hi')
  end

end