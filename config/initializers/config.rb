Config.setup do |config|
  # Name of the constant exposing loaded settings
  config.const_name = 'Settings'

  # Load environment variables from the `ENV` object and override any settings defined in files.
  config.use_env = true

  # Define ENV variable prefix deciding which variables to load into config.
  config.env_prefix = 'SETTINGS'

  # Bash-safe separator: SETTINGS__WEBHOOK__VERIFY_TOKEN -> Settings.webhook.verify_token
  config.env_separator = '__'

  # Convert variable names to lower case.
  config.env_converter = :downcase

  # Parse numeric values as integers instead of strings.
  config.env_parse_values = true

  # Evaluate ERB in YAML config files at load time.
  config.evaluate_erb_in_yaml = true
end
