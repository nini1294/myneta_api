# Run this with rackup
# Settings for rackup
#\ -o 0.0.0.0

require 'rack/unreloader'

# Initialise the Unloader while passing the subclasses to unload
# every time it detects changes
Unreloader = Rack::Unreloader.new(:subclasses => %w'Roda') {MyNeta}
Unreloader.require './my_neta.rb'

# Pass the favicon.ico location
use Rack::Static, :urls => ['/favicon.ico']

run Unreloader
