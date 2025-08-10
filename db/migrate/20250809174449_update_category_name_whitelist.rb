class UpdateCategoryNameWhitelist < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE categories
      DROP CONSTRAINT IF EXISTS categories_name_whitelist;
    SQL

    execute <<~SQL
      ALTER TABLE categories
      ADD CONSTRAINT categories_name_whitelist
      CHECK (name IN (
        'Vitamins',
        'Protein Supplements',
        'Digestive Health',
        'Skin Care',
        'Hair Care'
      ));
    SQL
  end

  def down
    # If you ever need to revert to the old whitelist, re-add it here.
    execute <<~SQL
      ALTER TABLE categories
      DROP CONSTRAINT IF EXISTS categories_name_whitelist;
    SQL
  end
end
