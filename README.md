# TlCapture

Timeline capture

## Installation

Add this line to your application's Gemfile:

    gem 'tl_capture', github: "HeRoMo/tl_capture"

And then execute:

    $ bundle install

## Usage

1. At first, prepare fluentd.
2. get your twitter application setting.
3. copy account_config.yml.template to account_config.yml, and make your config file
4. use tl_capture command to start capture your userstream.

```
  > bundle exec tl_capture tw_stream <YOUR CONFIG FILE>
```

## Contributing

1. Fork it ( https://github.com/HeRoMo/tl_capture/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
