Sequel.migration do
  up do
    create_table(:mp_contact_info) do
      primary_key :mp_id
      String :email
      column :phone_numbers, "text[]"
      foreign_key :mp_id, :mps
    end
  end

  down do
    drop_table(:mp_contact_info)
  end
end