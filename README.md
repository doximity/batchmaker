# Batchmaker

The Batchmaker is a simply utility that using a separate thread and an atomic queue, easily allows to
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

# Add items to the batchmaker queue
batchmaker << 1
batchmaker << 2
```

# Development

## Gem documentation

You can find the documentation by going to CircleCI, looking for the `build` job, going to Artifacts and clicking on `index.html`. A visual guide on this can be found in our wiki at [Gems Development: Where to find documentation for our gems](https://wiki.doximity.com/articles/gems-development-where-to-find-documentation-for-our-gems).

## Gem development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bundle console` for an interactive prompt that will allow you to experiment.

This repository uses a gem publishing mechanism on the CI configuration, meaning most work related with cutting a new
version is done automatically.

To release a new version, follow the [wiki instructions](https://wiki.doximity.com/articles/gems-development-releasing-new-versions).
