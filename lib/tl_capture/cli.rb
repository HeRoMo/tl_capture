require 'tl_capture'
require 'tl_capture/twitter/tw_client'
require 'tl_capture/twitter/tws_client'
require 'thor'

module TlCapture
  class CLI < Thor

    desc "tw_stream CONFIG_FILE","capture twitter userstream, output to fluentd"
    option :verbose, type: :boolean, aliases:'-v', desc: "print captured tweets"
    option :debug, type: :boolean, aliases:'-D', desc: "print captured tweets, not send to fluentd"
    def tw_stream(config_file="./account_config.yml")
      tws = TlCapture::TwsClient.new(config_file)
      tws.cap_stream(verbose:options[:verbose], debug:options[:debug])
    end


    desc "follows CONFIG_FILE","output follows"
    option :output_file, type: :string, aliases:'-o', desc: "output file name"
    def follows(config_file="./account_config.yml")
      tw = TlCapture::TwClient.new(config_file)
      tw.get_follows(options[:output_file])
    end

    desc "add_follows CONFIG_FILE","add follows of input file"
    option :input_file, type: :string, aliases:'-i',required:true, desc: "input follows list file"
    def add_follows(config_file="./account_config.yml")
      tw = TlCapture::TwClient.new(config_file)
      tw.add_follows(options[:input_file])
    end
  end
end
