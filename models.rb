require 'sequel'
$: << '../lib'

Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :validation_helpers

ENV['DATABASE_URL'] = 'postgres://pmyvxrkrgxnvxz:-sB3vkxwYpPYxLdBvLQyhMsVJc@ec2-54-83-20-177.compute-1.amazonaws.com:5432/d3volvoen2akce' unless ENV.include?('DATABASE_URL')
DB = Sequel.connect(ENV['DATABASE_URL'])

%w'mla mp'.each{|model| require "./models/#{model}.rb"}
