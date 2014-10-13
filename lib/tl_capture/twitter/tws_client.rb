require 'twitter'
require 'tweetstream'
require 'fluent-logger'
require 'yaml'
require 'pp'

module TlCapture
  # Twitter Stream Client
  class TwsClient

    # Constructor
    # @param config_file [String] set your account config file
    def initialize(config_file="./account_config.yaml")
      # Load config file and initialize
      account_config=YAML.load_file(config_file)
      TweetStream.configure do |config|
        config.consumer_key        = account_config["twitter"]["consumer_key"]
        config.consumer_secret     = account_config["twitter"]["consumer_secret"]
        config.oauth_token        = account_config["twitter"]["oauth_token"]
        config.oauth_token_secret = account_config["twitter"]["oauth_token_secret"]
        config.auth_method        = :oauth
      end
      @client = TweetStream::Client.new
      Fluent::Logger::FluentLogger.open(nil, :host=>'localhost', :port=>24224)
    end

    # Capture Userstream
    def cap_stream(verbose:false)
      puts "----- print captured tweet -----" if verbose
      @client.userstream do |status|
        tags=[]
        if status.hashtags
          status.hashtags.each do |tag|
            tags<<tag.text
          end
        end
        data = {
                :tweet_time=>status.created_at,
                :central_dep_name=>status.user.name,
                :local_gov_name=>"",
                :contents=>status.text,
                :hash_tag=>tags.join(",")}

        puts data if verbose # for DEBUG
        Fluent::Logger.post("source.twitter", data)
      end
    end

  end
end