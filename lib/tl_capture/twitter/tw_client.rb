require 'twitter'
require 'yaml'
require 'csv'

# Twitter::User へのモンキーパッチ
module TwitterUserExtension
  refine Twitter::User do
    # ユーザ名、プロフィールの説明に防災関連の特定キーワードがあるかどうかを判定する
    # @return 防災関連キーワードが含まれる場合 true それ以外は false
    def disaster_account?
      "#{self.description},#{self.name}"=~/(防災|災害|緊急|避難|震災|地震|洪水|火山|噴火)/ ? true:false
    end
  end
end

module TlCapture
  class TwClient
    using TwitterUserExtension

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

    # フォローしているアカウントを出力する。
    # @param output_file [String] 出力ファイル名。指定しない場合、標準出力に出力する
    def show_follows(output_file=nil)
      header = "screen_name,name,description,verified,followers_count,disaster_account"
      begin
        output = File.open(output_file, "w") if output_file
        puts header unless output
        output.write "#{header}\n" if output
        follows = get_follows
        follows.values.each do |user|
          line = "#{user.screen_name},#{user.name},'#{user.description}',#{user.verified?},#{user.followers_count},#{user.disaster_account?}"
          puts line unless output
          output.write "#{line}\n" if output
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

    # フォローしているアカウントを取得し、自治体リストに追記する。
    # @param input_file [String] フォローアカウントを追記する自治体リスト。screen_name カラムにTwitterのユーザ名を記入しておく
    # @param output_file [String] フォローアカウントを追記したリストを出力する
    def update_follow_list(input_file, output_file=nil)
      output_file=out_filename(input_file) if (output_file.nil? || output_file.to_s.size==0)
      follows = get_follows
      CSV.open(output_file, 'wb',quote_char:'"') do |out|
        out << ["code", "pref_name", "city_name", "pref_kana", "city_kana", "screen_name", "name", "description", "virified", "follower_count", "disaster_account"]
        CSV.foreach(input_file, headers: true) do |row|
          next if (row["code"].nil? || row["code"].to_i == 0)
          user = follows[row["screen_name"]]
          follows.delete(row["screen_name"])
          name = user.nil? ? "" : user.name
          desc = user.nil? ? "" : user.description
          verified = user.nil? ? "" : user.verified?
          f_count = user.nil? ? "" : user.followers_count
          disaster_account = user.nil? ? "" : user.disaster_account?
          out << [row['code'],row["pref_name"],row["city_name"],row["pref_kana"],row["city_kana"],row["screen_name"], name, desc, verified, f_count, disaster_account]
        end
        follows.values.each do |user|
          out << ["","地方公共団体以外にキャプチャしているツイッターアカウント","","","",user.screen_name, user.name, user.description, user.verified?, user.followers_count, user.disaster_account?]
        end
      end
    end

    private
    # フォローしているアカウントを取得する
    # @return [Hash] screen_name をキーにした フォローユーザのハッシュ
    def get_follows
      follows = {}
      follow_list = @client.friends({count:200})
      follow_list.each do |user|
        follows[user.screen_name] = user
      end
      return follows
    end

    # アウトプットファイルのファイルパスを生成する。
    def out_filename(filename)
      date_str = Date.today.strftime("%Y%m%d")
      outfile = "#{File.dirname(filename)}/#{File.basename(filename,".csv")}_#{date_str}.csv"
      puts outfile
      outfile
    end
  end
end

if __FILE__ == $0
   c = TlCapture::TwClient.new '/Users/hero/Develop/hackathon/tl_capture/account_config.yml'
   #c = TlCapture::TwClient.new '/Users/hero/Develop/hackathon/tl_capture/streamtest_config.yml'
   c.update_follow_list("/Users/hero/Develop/hackathon/tl_capture/doc/全国地方公共団体twitter_utf8.csv")
end