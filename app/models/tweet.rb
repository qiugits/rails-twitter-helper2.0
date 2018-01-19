#coding: utf-8
class Tweet < ApplicationRecord
  default_scope -> { order(status_id: :desc) } #http://techacademy.jp/magazine/7727
  scope :inbox, -> { where(tag: 'inbox')} #詳しい書き方例：　http://ruby-rails.hatenadiary.com/entry/20140814/1407994568
  scope :search_result , -> { where(tag: 'search')} #正規表現入れられないかな？

  account_name = ENV['TWITTER_USER_NAME'] #この手順を踏むのは、user_tweetsでこれをタグにするのに使うから
  keys = {
      ENV['TWITTER_USER_NAME'] => {
          consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
          consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
          access_token:        ENV['TWITTER_ACCESS_TOKEN'],
          access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET'],
      }
  }
  @@account = keys[account_name]

  def self.rest_endpoint
    consumer = OAuth::Consumer.new(
      @@account[:consumer_key],
      @@account[:consumer_secret],
      site:'https://api.twitter.com/'
    )
    rest_endpoint = OAuth::AccessToken.new(consumer, @@account[:access_token], @@account[:access_token_secret])
    return rest_endpoint
  end

  def self.mention_timeline
    #GET
    response = Tweet.rest_endpoint.get('https://api.twitter.com/1.1/statuses/mentions_timeline.json?count=200')
    #上の文字列（！）はJSON形式の文字列なので、Rubyで扱えるように、ハッシュに変換する。
    #http://uxmilk.jp/13387 <- 「JSON形式の文字列からハッシュへ変換する」の部分
    result = JSON.parse(response.body)
    Tweet.save_tweets_with_tag(result,"inbox")
  end

#endpointの中身がまだない
  def self.user_tweets
    #VaingloryJPのツイートを読み込む
    response = Tweet.rest_endpoint.get('https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{account_name}&count=200&include_rts=false')#someting!
    result = JSON.parse(response.body)
    #それをデータベースに格納
    Tweet.save_tweets_with_tag(result,account_name) #account_nameをタグとして保存
  end

  def self.save_tweets_with_tag(parse_result,tag)
    #Timeline.delete_all #すべて消去しておく http://railsdoc.com/model
    parse_result.each do |res|
      begin
        @t = Tweet.new #@がつくのはインスタンス変数。
        @t.status_id = res["id"]
        @t.created_at = res["created_at"]
        #@t.text = Tweet.add_html_to_username_or_link(res["text"])
        @t.text = res["text"]
        img_url = ""
        begin
          res["entities"]["media"].each{|img| img_url = img["media_url_https"]}
        rescue
        end
        @t.media = img_url
        @t.source = res["source"]
        @t.in_reply_to_status_id = res["in_reply_to_status_id"]
        @t.user_screen_name = res["user"]["screen_name"]
        @t.user_profile_image = res["user"]["profile_image_url_https"]
        @t.tag = tag
        #@t.memo = ?
        @t.save
      rescue #status_idが重複した時エラーとなるので、nextする。
        next
      end
    end
  end

#正規表現で変えようとするが、うまくいかん。データベースに入ったタグ表現は表示するときにタグじゃなくなる
=begin
  def self.add_html_to_username_or_link(text)
    text2 = text
    text2.gsub!(/(@[a-zA-Z1-9_]+)\s/,"<span class=\"name_or_link\">#{$1}</span>")
    #text2.gsub!(/(https?:\/\/[\w\/:%#\$&\?\(\)~\.=\+\-]+)\s?/,"<span class=\"name_or_link\">#{$1}</span>")
    return text2
  end
=end

  def self.post(text, id)
    #POST
    response_post = Tweet.rest_endpoint.request(:post,'https://api.twitter.com/1.1/statuses/update.json',status: text, in_reply_to_status_id: id)
    #いましたツイートをデータベースに収納
    result_post = JSON.parse(response_post.body)
    Tweet.save_tweets_with_tag([result_post],"VaingloryJP")
  end

  def self.reply(text, id)
    @tweet_to_reply = Tweet.find_by(status_id: id)
    #Tweet.post("@#{@tweet_to_reply.user_screen_name} #{text}",id)
    Tweet.post(text, id) #Twitterが新しくなって＠いらなくなったみたいなので。
  end

  def self.change_tag(id,new_tag)
    @tweet_to_change_tag = Tweet.find_by(status_id: id)
    @tweet_to_change_tag.update(tag: new_tag) #こっちのがrailsドキュメントより正確？　http://ruby-rails.hatenadiary.com/entry/20140724/1406142120
  end

  def self.string_to_ascii(string)
    #日本語がまだ扱えない
    newstring = ""
    string.chars{|c|
      if /[a-zA-Z]/ =~ c
        newstring += c
      else
        cc = c.bytes
        cc.each{|ccc| newstring = newstring + "%" + ccc.to_s(16)} #URLが受け付けるのは16進数(Hexadecimal)。
      end
    }
    return string = newstring
  end

  def self.search(keyword)
    #GET
    #URLの中ではASCII規格の文字コード？しか使えない。　変換機：http://web-apps.nbookmark.com/ascii-converter/
    keyword_ascii = Tweet.string_to_ascii(keyword)
    i = 0
    max_id = ""
    last_id = nil
    while i < 10
      response = Tweet.rest_endpoint.get("https://api.twitter.com/1.1/search/tweets.json?q=#{keyword_ascii}&count=100&lang=ja&result_type=mixed&since_id=782818399382495232#{max_id}")
      result = JSON.parse(response.body)
      Tweet.save_tweets_with_tag(result["statuses"],"search") #このresultは"statuses"と"search_metadata"にまず分かれていて、"statuses"の中でやっと個々のツイートに出くわす。
      if result["statuses"].empty?
        break
      else
        last_id = result["statuses"][-1]["id"]
        max_id = "&max_id=#{last_id - 1}" unless last_id.nil?
      end
      i += 1
    end
  end

=begin
  def self.origintweetid(id)
    result = Array.new
    while true
      #GET
      #https://dev.twitter.com/rest/reference/get/statuses/show/%3Aid
      response = Timeline.rest_endpoint(@@VaingloryJP).get("https://api.twitter.com/1.1/statuses/show.json?id=#{id}")
      res = JSON.parse(response.body)
      result.unshift(res) #unshiftで前から挿入
      next if id = res["in_reply_to_status_id"]
      break
    end
    Timeline.viewtl(result)
  end
=end
end
