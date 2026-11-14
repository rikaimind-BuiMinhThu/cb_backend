# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
# Partial-key match: :card also covers card_number, card_holder, etc.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :card, :cvc, :cvv, :security_code, :pan, :credit_card, :shop_pass, :ipcode,
  :authorization, :api_key, :cookie
]
