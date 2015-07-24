require 'sequel'

Sequel.migration do
    up do
        alter_table(:mlas) do
            add_unique_constraint(:constituency, :name => :unique_constituency)
        end
    end
    down do
        alter_table(:mlas) do
            drop_constraint(:unique_constituency)
        end
    end
end