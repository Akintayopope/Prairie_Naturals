class FixCouponsSchema < ActiveRecord::Migration[8.0]
  def up
    # 1) enum backing column
    add_column(:coupons, :discount_type, :integer, null: false, default: 0) \
      unless column_exists?(:coupons, :discount_type)

    # 2) value column (migrate from :discount if present)
    if !column_exists?(:coupons, :value)
      if column_exists?(:coupons, :discount)
        add_column :coupons, :value, :decimal, precision: 10, scale: 2
        execute "UPDATE coupons SET value = discount::decimal"
        change_column_null :coupons, :value, false, 0
        remove_column :coupons, :discount
      else
        add_column :coupons, :value, :decimal, precision: 10, scale: 2, null: false, default: 0
      end
    end

    # 3) other fields the model expects
    add_column(:coupons, :max_uses,   :integer)                          unless column_exists?(:coupons, :max_uses)
    add_column(:coupons, :uses_count, :integer, null: false, default: 0) unless column_exists?(:coupons, :uses_count)
    add_column(:coupons, :starts_at,  :datetime)                         unless column_exists?(:coupons, :starts_at)
    add_column(:coupons, :ends_at,    :datetime)                         unless column_exists?(:coupons, :ends_at)
    add_column(:coupons, :active,     :boolean, null: false, default: true) unless column_exists?(:coupons, :active)

    # 4) indexes
    add_index :coupons, :code, unique: true unless index_exists?(:coupons, :code, unique: true)
    add_index :coupons, [ :active, :starts_at, :ends_at ], name: "index_coupons_on_active_and_window" \
      unless index_exists?(:coupons, [ :active, :starts_at, :ends_at ], name: "index_coupons_on_active_and_window")

    # 5) Postgres check constraint (skip if already present)
    if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
      constraint_exists = <<~SQL
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'coupons_value_percent_cap_chk'
      SQL
      unless ActiveRecord::Base.connection.select_value(constraint_exists)
        execute <<~SQL
          ALTER TABLE coupons
          ADD CONSTRAINT coupons_value_percent_cap_chk
          CHECK (
            (discount_type = 0 AND value <= 100)
            OR (discount_type = 1)
          );
        SQL
      end
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
      execute "ALTER TABLE coupons DROP CONSTRAINT IF EXISTS coupons_value_percent_cap_chk;"
    end

    remove_index :coupons, name: "index_coupons_on_active_and_window" \
      if index_exists?(:coupons, [ :active, :starts_at, :ends_at ], name: "index_coupons_on_active_and_window")
    remove_index :coupons, :code if index_exists?(:coupons, :code)

    remove_column(:coupons, :active)     if column_exists?(:coupons, :active)
    remove_column(:coupons, :ends_at)    if column_exists?(:coupons, :ends_at)
    remove_column(:coupons, :starts_at)  if column_exists?(:coupons, :starts_at)
    remove_column(:coupons, :uses_count) if column_exists?(:coupons, :uses_count)
    remove_column(:coupons, :max_uses)   if column_exists?(:coupons, :max_uses)

    unless column_exists?(:coupons, :discount)
      add_column :coupons, :discount, :decimal, precision: 10, scale: 2
      execute "UPDATE coupons SET discount = value::decimal" if column_exists?(:coupons, :value)
    end
    remove_column(:coupons, :value)         if column_exists?(:coupons, :value)
    remove_column(:coupons, :discount_type) if column_exists?(:coupons, :discount_type)
  end
end
