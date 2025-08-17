# Returns true if a table/data source exists (without blowing up on boot)
def admin_table?(name)
  ActiveRecord::Base.connection.data_source_exists?(name)
rescue StandardError
  false
end
