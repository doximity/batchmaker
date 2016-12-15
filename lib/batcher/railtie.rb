class Batcher
  class Railtie < Rails::Railtie
    initializer 'Rails Logger' do
      Batcher.logger = Rails.logger
    end
  end
end
