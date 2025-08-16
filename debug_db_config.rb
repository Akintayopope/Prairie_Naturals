#!/usr/bin/env ruby
require_relative 'config/environment'

puts "Current database configuration:"
puts Rails.application.config.database_configuration['development'].inspect

puts "\nEnvironment variables:"
ENV.each do |key, value|
  puts "#{key}=#{value}" if key.include?('PG') || key.include?('DATABASE')
end
