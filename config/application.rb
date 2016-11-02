require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FriendlyCSV
  class Application < Rails::Application
    config.autoload_paths << Rails.root.join('lib') # adds Lib folder to autoloaded files
    config.autoload_paths += %W(#{config.root}/app/services)

    # sendgrid
    ActionMailer::Base.smtp_settings = {
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :domain => 'ryanckulp.com',
      :address => 'smtp.sendgrid.net',
      :port => 587,
      :authentication => :plain,
      :enable_starttls_auto => true
    }

    # paperclip
    config.paperclip_defaults = {
      storage: :s3,
      s3_credentials: {
          bucket: ENV['AWS_BUCKET'],
          access_key_id: ENV['AWS_ACCESS'],
          secret_access_key: ENV['AWS_SECRET']
      }
    }

    config.active_record.raise_in_transactional_callbacks = true

    # disable superfluous generator extras
    config.generators do |g|
      g.assets = false # remove auto stylesheets
      g.helper = true
    end

  end
end
