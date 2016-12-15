class Batcher
  class Railtie < Rails::Railtie
    initializer 'batcher.configure_logger' do
      Batcher.logger = Rails.logger
    end
  end
end
