Sequel.migration do
  up do
    create_table(:mp_contact_info) do
      String :email, size: 50
      column :phone_numbers, "text[]"
      foreign_key :mp_id, :mps
    end
  end

  down do
    drop_table(:mp_contact_info)
  end
end
