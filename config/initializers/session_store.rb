# Be sure to restart your server when you modify this file.

# Rails.application.config.session_store :cookie_store, key: '_session-test_session'
Rails.application.config.redis_connection_params = {
  :host => "localhost",
  :port => 6379,
  :db => 0,
  :expires_in => 90.minutes
}
Rails.application.config.session_store :redis_store, Rails.application.config.redis_connection_params
