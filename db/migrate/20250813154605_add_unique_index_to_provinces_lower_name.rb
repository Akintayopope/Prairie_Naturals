class AddUniqueIndexToProvincesLowerName < ActiveRecord::Migration[7.2]
  def change
    # Expression index (Postgres) for case-insensitive unique names
    add_index :provinces, "LOWER(name)", unique: true, name: "index_provinces_on_lower_name_unique"
  end
end
