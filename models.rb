require 'sequel'
$: << '../lib'

Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :validation_helpers

DB = Sequel.connect(ENV['DATABASE_URL'])

%w'mla'.each{|model| require "./models/#{model}.rb"}