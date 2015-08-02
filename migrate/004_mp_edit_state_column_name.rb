Sequel.migration do
    up do
        rename_column :mps, :state, :state_or_ut
    end

    down do
        rename_column :mps, :state_or_ut, :state
    end
end