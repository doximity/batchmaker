# Batcher

The `Batcher` class was originally introduced in https://github.com/doximity/doximity/pull/15766 in order to batch email sends together. This ensures that every email sent will be put on a queue, and will be automatically sent by the system when the queue has hit a certain size or a specified time period has elapsed (whichever comes first).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'batcher'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install batcher

## Usage

The batcher class requires several arguments on initialization:
```
batcher = Batcher.new(name, size, tick_period, logger, notifier = nil, &block)
```

`name` - The name of the queue (for emails, referencing the priority of the worker, e.g. critical, default, low)

`size` - Size of the queue

`tick_period` - The amount of time to wait before processing the queue

`logger` - Rails logger

`notifier` - Bugsnag notifier class (`ExceptionNotification`)

`&block` - Action to occur when the queue is processed (In this case, enqueuing the message data to the specified send email worker)

```
batcher = Batcher.new("email-default", 100, 20, Rails.logger, ExceptionNotification) do |messages|
  Emails::SendEmailDefaultWorker(messages.as_json)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run bundle exec rake install. To release a new version, update the VERSION number in lib/batcher.rb, and then follow the instructions for releasing it as a private gem on Gemfury.

