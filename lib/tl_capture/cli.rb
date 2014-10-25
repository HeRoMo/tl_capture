require 'tl_capture'
require 'tl_capture/twitter/tws_client'
require 'thor'

module TlCapture
  class CLI < Thor

    desc "tw_stream FILE","capture twitter userstream, output to fluentd"
    option :verbose, type: :boolean, aliases:'-v', desc: "print captured tweets"
    option :debug, type: :boolean, aliases:'-D', desc: "print captured tweets, not send to fluentd"
    def tw_stream(config_file="./account_config.yml")
      tws = TlCapture::TwsClient.new(config_file)
      tws.cap_stream(verbose:options[:verbose], debug:options[:debug])
    end
  end
end
