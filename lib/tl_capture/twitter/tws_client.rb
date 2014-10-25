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

    end

    # Capture Userstream
    def cap_stream(verbose:false, debug:false)

      Fluent::Logger::FluentLogger.open(nil, :host=>'localhost', :port=>24224) unless debug
      puts "----- print captured tweet -----" if verbose
      puts "----- print captured tweet on DEBUG MODE-----" if debug
      client = TweetStream::Client.new

      # エラー次の処理
      client.on_error do |message|
        puts message
      end

      client.on_event(:favorite) do |event|
        puts "[EVENT] #{event.to_s}"
      end
      client.userstream do |status|
        puts "[STATUS] #{status.to_s}"
        tags=[]
        if status.hashtags
          status.hashtags.each do |tag|
            tags<<tag.text
          end
        end
        data = {
                :tweet_time=>status.created_at,
                :tweet_time_jst=>status.created_at.strftime("%Y-%m-%d %H:%M:%S"),
                :user_id=>status.user.id,
                :author=>status.user.screen_name,
                :author_name=>status.user.name,
                :contents_id=>status.id,
                :contents=>status.text,
                :hash_tag=>tags.join(","),
                :friends_count=>status.user.friends_count,
                :followers_count=>status.user.followers_count}

        puts data if verbose || debug # for DEBUG
        Fluent::Logger.post("source.twitter", data) unless debug
      end
    end
  end
end