# config/initializers/safe_mode.rb
require "active_model"

# One switch to turn off optional integrations at boot
SAFE_MODE       = ActiveModel::Type::Boolean.new.cast(ENV["SAFE_MODE"] || ENV["BYPASS_OPTIONAL"])
DISABLE_STRIPE  = SAFE_MODE || ENV["DISABLE_STRIPE"]  == "1"
DISABLE_DISCORD = SAFE_MODE || ENV["DISABLE_DISCORD"] == "1"
