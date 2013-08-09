# PbActor

Process based Actor.

## Installation

Add this line to your application's Gemfile:

    gem 'pb_actor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pb_actor

## Usage

```ruby
require 'pb_actor'

class Test
  include PbActor
  def fib(n)
    if n < 2
      1
    else
      fib(n - 1) + fib(n - 2)
    end
  end

  def p_fib(n)
    puts fib(n)
  end
end

f = Test.new
#=> <PbActor::Proxy:0x00000002106448 @origin=#<Test:0x00000002106470>, @pid=23487, @rd=#<IO:fd 7>, @wr=#<IO:fd 10>>

f.alive?
#=> true

f.fib(30)
#=> 1346269

f.async.p_fib(30)
#=> nil
# 1346269

f.terminate
f.alive?
#=> false
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
