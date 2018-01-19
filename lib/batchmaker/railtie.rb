class Batchmaker
  class Railtie < Rails::Railtie
    initializer 'batcher.configure_logger' do
      Batchmaker.logger = Rails.logger
    end
  end
end
