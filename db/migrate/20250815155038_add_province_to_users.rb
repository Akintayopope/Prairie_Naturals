# db/migrate/20250815xxxxxx_add_province_to_users.rb
class AddProvinceToUsers < ActiveRecord::Migration[8.0]
  def change
    # 1) Add users.province_id with FK + index
    add_reference :users, :province, foreign_key: true, index: true

    # 2) Backfill from the user's most recent address (if any)
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE users u
          SET province_id = a.province_id
          FROM addresses a
          WHERE a.user_id = u.id
          AND a.id = (
            SELECT id FROM addresses a2
            WHERE a2.user_id = u.id
            ORDER BY a2.created_at DESC
            LIMIT 1
          )
        SQL
      end
    end
  end
end
