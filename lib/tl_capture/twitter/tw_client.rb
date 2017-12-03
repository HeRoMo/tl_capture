require 'twitter'
require 'yaml'
require 'csv'

# Twitter::User へのモンキーパッチ
module TwitterUserExtension
  refine Twitter::User do
    # ユーザ名、プロフィールの説明に防災関連の特定キーワードがあるかどうかを判定する
    # @return 防災関連キーワードが含まれる場合 true それ以外は false
    def disaster_account?
      "#{self.description},#{self.name}"=~/(防災|災害|緊急|避難|震災|地震|洪水|火山|噴火|大雪)/ ? true:false
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
    # TODO このメソッドは文字列を返すだけにしたほうが良い。ファイルや標準出力への出力はCLIでやるべき
    def show_follows(output_file=nil)
      header = ["screen_name","name","description","verified","followers_count","disaster_account"]
      output = CSV.generate do |csv|
        csv.puts header
        follows = get_follows
        follows.values.each do |user|
          line = [user.screen_name,user.name,user.description,user.verified?,user.followers_count,user.disaster_account?]
          csv.puts line
        end
      end
      if output_file
        File.open(output_file, "w") do |file|
          file.puts output
        end
      else
        $stdout.puts output
      end
    end

    # ファイルを読み込みフォローを追加する
    # @param follow_list_file [String] フォローしたいスクリーンネームを1列目に含むCSVファイルを指定する
    # @return [Array<Twitter::User>] 新たにフォローしたユーザ
    def add_follows(follow_list_file)
      twitter_ids = open(follow_list_file,"r") do |file|
        file.readlines
      end
      if twitter_ids.size > 0
        twitter_ids = twitter_ids.uniq.map(&:strip)
      end
      added_user =[]
      split_array(twitter_ids, 100).each do |ids|
        added_user += @client.follow(ids)
      end
      added_user.sort{|a,b| a.screen_name <=> b.screen_name}
    end

    # フォローしているアカウントを取得し、自治体リストに追記する。
    # @param input_file [String] フォローアカウントを追記する自治体リスト。screen_name カラムにTwitterのユーザ名を記入しておく
    # @param output_file [String] フォローアカウントを追記したリストを出力する
    def update_follow_list(input_file, output_file=nil)
      output_file=out_filename(input_file) if (output_file.nil? || output_file.to_s.size==0)
      follows = get_follows
      CSV.open(output_file, 'wb',quote_char:'"') do |out|
        out << ["code", "pref_name", "city_name", "pref_kana", "city_kana", "order", "screen_name", "name", "description", "virified", "follower_count", "tweet_count", "disaster_account", "created_at"]
        CSV.foreach(input_file, headers: true) do |row|
          next if (row["code"].nil? || row["code"].to_i == 0)
          user = follows[row["screen_name"]]
          follows.delete(row["screen_name"])
          name = user.nil? ? "" : user.name
          desc = user.nil? ? "" : user.description
          verified = user.nil? ? "" : user.verified?
          f_count = user.nil? ? "" : user.followers_count
          t_count = user.nil? ? "" : user.statuses_count
          disaster_account = user.nil? ? "" : user.disaster_account?
          created_at = user.nil? ? "" : user.created_at.strftime('%Y-%m-%d')
          out << [row['code'],row["pref_name"],row["city_name"],row["pref_kana"],row["city_kana"],row["order"],row["screen_name"], name, desc, verified, f_count, t_count, disaster_account, created_at]
        end
        follows.values.each do |user|
          out << ["","地方公共団体以外にキャプチャしているツイッターアカウント","","","","",user.screen_name, user.name, user.description, user.verified?, user.followers_count, user.statuses_count, user.disaster_account?, user.created_at.dup.localtime]
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

    # 出力ファイルのファイルパスを生成する。
    # @param filename [String] 出力ファイルの元となるファイルパス
    def out_filename(filename)
      date_str = Date.today.strftime("%Y%m%d")
      outfile = "#{File.dirname(filename)}/#{File.basename(filename,".csv")}_#{date_str}.csv"
      outfile
    end

    # 配列を指定した数で分割する
    # @param array [Array] 分割する配列
    # @param num [Integer] 分割後の配列の要素数。
    # @return [Array<Array>] 指定した要素数に分割された配列
    def split_array(array, num)
      res = []
      t = (array.size.to_f/num).ceil
      t.times do |i|
        res << array[i*num,num]
      end
      res
    end
  end
end