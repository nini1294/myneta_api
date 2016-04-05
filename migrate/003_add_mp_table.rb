Sequel.migration do
    up do
        create_table(:mps) do
            primary_key :mp_id
            String :state, null: false
            String :name, null: false
            String :constituency, null: false
            String :party, null: false
            Integer :criminal_cases, null: false
            String :education, null: false
            BigDecimal :assets, size: [12, 2]
            Integer :year, null: false
            unique([:name, :constituency, :state, :year], :name => :unique_mp)
        end
    end

    down do
        drop_table(:mps)
    end
end
