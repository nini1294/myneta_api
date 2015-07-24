# Run this with rackup
# Settings for rackup
#-p 3012
ENV['DATABASE_URL'] = 'postgres://pmyvxrkrgxnvxz:-sB3vkxwYpPYxLdBvLQyhMsVJc@ec2-54-83-20-177.compute-1.amazonaws.com:5432/d3volvoen2akce' unless ENV.include?('DATABASE_URL')

require './my_neta.rb'

use Rack::Static, :urls => ['/favicon.ico']

run MyNeta.freeze.app
