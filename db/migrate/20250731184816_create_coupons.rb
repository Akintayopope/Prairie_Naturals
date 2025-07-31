class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.string :code
      t.decimal :discount
      t.boolean :active

      t.timestamps
    end
  end
end
