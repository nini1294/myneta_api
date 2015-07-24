require 'sequel'

Sequel.migration do
    up do
        alter_table(:mlas) do
            add_unique_constraint([:constituency, :state], :name => :unique_mla)
        end
    end
    down do
        alter_table(:mlas) do
            drop_constraint(:unique_mla)
        end
    end
end