require 'sequel'
$: << '../lib'

Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :validation_helpers

DBURL = ENV.fetch('DATABASE_URL')
DB = Sequel.connect(DBURL)

%w'mla mp'.each{|model| require "./models/#{model}.rb"}
