# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Gem.loaded_specs["bootstrap"].load_paths.first
