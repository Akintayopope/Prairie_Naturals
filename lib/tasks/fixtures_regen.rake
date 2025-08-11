require "yaml"
require "securerandom"

namespace :fixtures do
  desc "Regenerate minimal fixtures for ALL tables from the test DB schema"
  task regenerate: :environment do
    abort "Run with RAILS_ENV=test" unless Rails.env.test?

    conn = ActiveRecord::Base.connection

    IGNORE = %w[ar_internal_metadata schema_migrations]

    # Hard overrides for tricky constraints (edit as needed)
    OVERRIDES = {
      "categories" => { "name" => "Vitamins" }
    }

    tables = conn.tables.reject { |t| IGNORE.include?(t) }

    # Build dependency graph so parents are created before children
    deps    = Hash.new { |h, k| h[k] = [] }
    reverse = Hash.new { |h, k| h[k] = [] }
    tables.each do |t|
      conn.foreign_keys(t).each do |fk|
        next if IGNORE.include?(fk.to_table)
        deps[t] << fk.to_table
        reverse[fk.to_table] << t
      end
    end

    # Topological sort
    in_deg = Hash.new(0)
    tables.each { |t| in_deg[t] = deps[t].uniq.size }
    queue = tables.select { |t| in_deg[t].zero? }
    order = []
    until queue.empty?
      n = queue.shift
      order << n
      reverse[n].each do |m|
        in_deg[m] -= 1
        queue << m if in_deg[m].zero?
      end
    end
    order = tables if order.size != tables.size # fallback if cycle

    fixtures_dir = Rails.root.join("test/fixtures")
    FileUtils.mkdir_p(fixtures_dir)
    puts "Writing fixtures to #{fixtures_dir}..."

    order.each do |table|
      cols = conn.columns(table)
      col_by = cols.index_by(&:name)
      pk = conn.primary_key(table) || "id"

      row = {}
      row[pk] = 1 if col_by.key?(pk)

      cols.each do |c|
        next if c.name == pk
        next if %w[created_at updated_at].include?(c.name)

        if c.name.end_with?("_id")
          row[c.name] = 1
        elsif !c.default.nil?
          row[c.name] = c.default
        else
          row[c.name] =
            case c.type
            when :string, :text then "#{table}_value"
            when :integer, :bigint then 1
            when :decimal, :float then 1.0
            when :boolean then false
            when :date then Date.today
            when :datetime, :timestamp, :time then Time.now
            when :uuid then SecureRandom.uuid
            else nil
            end
        end
      end

      # Ensure NOT NULL columns are set
      cols.reject(&:null).each do |c|
        next if row.key?(c.name)
        row[c.name] =
          case c.type
          when :string, :text then "#{table}_value"
          when :integer, :bigint then 1
          when :decimal, :float then 1.0
          when :boolean then false
          when :date then Date.today
          when :datetime, :timestamp, :time then Time.now
          when :uuid then SecureRandom.uuid
          else 0
          end
      end

      # Apply overrides (e.g., category name whitelist)
      row.merge!(OVERRIDES[table]) if OVERRIDES[table]

      yaml = { "one" => row }.to_yaml
      File.write(fixtures_dir.join("#{table}.yml"), yaml)
      puts "  - #{table}.yml"
    end

    puts "Done."
  end
end
