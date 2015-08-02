class MP < Sequel::Model
    # Helper formatting method, takes a parameter specifying what to delete
    def format(delete = [:mp_id])
        tmp = @values
        # Delete each parameter passed in
        delete.each do |param|
            tmp.delete(param)
        end
        tmp[:assets] = tmp[:assets].to_f unless tmp[:assets].nil?
        return tmp
    end
end