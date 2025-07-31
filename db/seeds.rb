# db/seeds.rb

puts "Seeding categories..."
categories = %w[Hair Skin Vitamins Supplements Body]
categories.each do |name|
  Category.find_or_create_by!(name: name)
end

puts "Seeding provinces..."
provinces = [
  { name: "Ontario", pst: 0.08, gst: 0.05, hst: 0.13 },
  { name: "Manitoba", pst: 0.07, gst: 0.05, hst: 0.0 },
  { name: "Alberta", pst: 0.0, gst: 0.05, hst: 0.0 },
  { name: "British Columbia", pst: 0.07, gst: 0.05, hst: 0.0 },
  { name: "Quebec", pst: 0.09975, gst: 0.05, hst: 0.0 }
]

provinces.each do |prov|
  Province.find_or_create_by!(name: prov[:name]) do |p|
    p.pst = prov[:pst]
    p.gst = prov[:gst]
    p.hst = prov[:hst]
  end
end

puts "Seeding completed!"
