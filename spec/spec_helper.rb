require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tl_capture'
require 'webmock/rspec'
require 'vcr'
require 'csv'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
end

def read_file(filepath)
  out = StringIO.new
  CSV.foreach(filepath, quote_char:'"') do |line|
    out.puts line.to_a.join(',')
  end
  out.string
end

def read(filepath)
  File.open(filepath).read
end