# Be sure to restart your server when you modify this file.

# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
# Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
# Rails.application.config.time_zone = 'Central Time (US & Canada)'

# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# Rails.application.config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
# Rails.application.config.i18n.default_locale = :de

# Not sure why we need this, but it fixes this deprecation warning:
# --
# [deprecated] I18n.enforce_available_locales will default to true in the future.
# If you really want to skip validation of your locale you can set
# I18n.enforce_available_locales = false to avoid this message.
I18n.enforce_available_locales = true
