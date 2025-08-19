require "json"
Rails.application.eager_load!

data = {}
ActiveRecord::Base.descendants.each do |m|
  begin
    next if m.abstract_class? || !m.table_exists?
  rescue
    next
  end

  presence = m.validators
               .grep(ActiveModel::Validations::PresenceValidator)
               .flat_map(&:attributes)
               .map(&:to_s).uniq.sort

  notnull = m.columns
              .select { |c| !c.null && c.default.nil? }
              .map(&:name).sort

  data[m.name] = { presence: presence, db_null_false: notnull } \
    unless presence.empty? && notnull.empty?
end

FileUtils.mkdir_p("tmp")
File.write("tmp/required_fields.json", JSON.pretty_generate(data))
puts "➡️  Wrote tmp/required_fields.json"
