# Run this with rackup
# Settings for rackup
#-p 3012

require './my_neta.rb'

use Rack::Static, :urls => ['/favicon.ico']

run MyNeta.freeze.app
