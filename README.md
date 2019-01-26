# SimpleCircuit

A simple implementation of [Circuit Breaker](https://en.wikipedia.org/wiki/Circuit_breaker_design_pattern) pattern.

Use it when you make calls to an unreliable service. It will not make the service reliable, but it will **fail fast** when the service is down, to prevent overload in your app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_circuit' # Circuit breaker to fail fast on external service outages
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_circuit

## Usage

Suppose you have calls to unreliable services like these:

```ruby
client = UnreliableServiceClient.new(url: "https://api.example.io")
client.get_some_info # => "foo bar"
```

When they go down or unresponsive, your app starts to slow down too. Queues filling up, etc.

If you'd rather have the calls fail fast, and handle failures fast, use it through a circuit:

```ruby
client = UnreliableServiceClient.new(url: "https://api.example.io")
circuit = SimpleCircuit.new(payload: client)
circuit.pass(:get_some_info) # => "foo bar"
```

You're passing the same message (`get_some_info`) to `client` object, but now it goes through a circuit.
It works exactly the same while the circuit is closed (there are no problems in the payload).

Interesting things begin when `client` starts throwing errors.

The first few errors (100 by default) are returned as is:

```ruby
circuit.pass(:get_some_info) # => HTTP::TimeoutError
```

This is still slow because it's the `client` object still working as usual.

But after 100 errors, the circuit **breaks**.
The payload is disconnected from the circuit.
It no longer receives the `get_some_info` message.
Instead, the circuit itself immediately throws the error.
So, each call will fail fast.
This will prevent overload in your app while the service is down.
This will also reduce the load on the service and hopefully allow it to recover faster.

The circuit will keep trying to connect the payload back and send the message through it, at regular intervals (by default, every minute).
When it succeeds, it will become closed again and will rely _all_ messages to the payload, just like in the beginning.

### Customization

You can customize several parameters of circuits. The defaults are show below:

```ruby
circuit = SimpleCircuit.new(payload: client, max_failures: 100, retry_in: 60, logger: nil)
```

The parameters are:

* `max_failures` — How many exceptions from the payload should be ignored (returned as is) before the circuit breaks and starts to fail fast.
* `retry_in` — How many seconds should pass before every retry to connect the payload (to send the original message) when the circuit is open (broken).
* `logger` — An object that responds to `warn(message)`. It will be called each time the circuit is broken.

### Error Counting

The circuit counts exceptions coming from the payload **by class** and breaks only if **a particular class** of exceptions is received too many times.
It fails fast with the most occurred exception.

For example, if the payload occasionally throws `MultiJson::ParseError` and then starts throwing `HTTP::TimeoutError` on a regular basis, then the counter of `HTTP::TimeoutError` will reach the maximum first, and the circuit will fast-throw `HTTP::TimeoutError` after breaking.

It might be non-ideal. I welcome suggestions via issues or pull requests.

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `bundle exec rake` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/circuit.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vassilevsky/circuit.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
