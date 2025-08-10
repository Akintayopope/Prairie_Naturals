class CreateStaticPages < ActiveRecord::Migration[8.0]
  def change
    create_table :static_pages do |t|
      t.string :title
      t.string :slug
      t.text :body

      t.timestamps
    end
    add_index :static_pages, :slug
  end
end
