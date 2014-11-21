require 'twitter'

module TlCapture
  class TwClient

    # コンストラクタ
    # @param config_file [String] アカウント情報を含むコンフィグファイル
    def initialize(config_file="./account_config.yaml")
      account_config=YAML.load_file(config_file)
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key        = account_config["twitter"]["consumer_key"]
        config.consumer_secret     = account_config["twitter"]["consumer_secret"]
        config.access_token        = account_config["twitter"]["oauth_token"]
        config.access_token_secret = account_config["twitter"]["oauth_token_secret"]
      end
    end

    # フォローしているアカウントを取得する
    # @param output_file [String] 出力ファイル名。指定しない場合、標準出力に出力する
    def get_follows(output_file=nil)
      begin
        output = File.open(output_file, "w") if output_file
        puts "screen_name,name,description,verified,followers_count,disaster information" unless output
        output.write "screen_name,name,description,verified,followers_count,disaster information\n" if output
        follows = @client.friends({count:200})
        follows.each do |user|
          bousai = (user.description+user.name)=~/(防災|災害|緊急|避難|震災)/ ? true:false
          puts "#{user.screen_name},#{user.name},'#{user.description}',#{user.verified?},#{user.followers_count},#{bousai}" unless output
          output.write "#{user.screen_name},#{user.name},'#{user.description}',#{user.verified?},#{user.followers_count},#{bousai}\n" if output
        end
      ensure
        output.close if output
      end
    end

    # ファイルを読み込みフォローを追加する
    # @param follow_list_file [String] フォローしたいスクリーンネームを1列目に含むCSVファイルを指定する
    def add_follows(follow_list_file)
      open(follow_list_file,"r") do |file|
        i = 0
        twitter_ids = []
        file.each do |line|
          i+=1
          twitter_id = line.strip
          twitter_ids << twitter_id
          if i%100 == 0
            p twitter_ids
            @client.follow twitter_ids
            twitter_ids.clear
          end
        end
        p twitter_ids
        @client.follow twitter_ids
      end
    end
  end
end