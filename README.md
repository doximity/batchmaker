# Batchmaker

The Batchmaker is a simply utility that using a separate thread and a atomic queue, easily allows to
store objects on the queue and perform a operation on a batch of the objects. The batch is
controlled by a maximum size and a tick period, ensuring that the batch have at most N objects or
that at most M time-unit have elapsed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'batchmaker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install batchmaker

## Usage

The batchmaker class requires several arguments on initialization:
```
batchmaker = Batchmaker.new(name, size, tick_period, on_error: nil, &block)
```

`name` - The name of the queue (for emails, referencing the priority of the worker, e.g. critical, default, low)

`size` - Size of the queue

`tick_period` - The amount of time to wait before processing the queue

`on_error` - Optional error callback (Proc)

`&block` - Action to occur when the queue is processed (In this case, enqueuing the message data to the specified send email worker)

```
BATCH_EXCEPTION_NOTIFIER = -> (err, ident_str) {
  ExceptionNotification.log_and_notify(err, batchmaker_id: ident_str)
}

batchmaker = Batchmaker.new("email-default", 100, 20, on_error: BATCH_EXCEPTION_NOTIFIER) do |batch|
  Emails::SendEmailDefaultWorker(batch.as_json)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run bundle exec rake install. To release a new version, update the VERSION number in lib/batchmaker.rb, and then follow the instructions for releasing it as a private gem on Gemfury.

