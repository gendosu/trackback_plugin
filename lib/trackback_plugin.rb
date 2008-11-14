# TrackbackPlugin
module TrackbackPlugin #:nodoc:
  def self.included(base)
    base.extend(ClassMethods)
  end

  # オプション
  # title_column :: 記事のタイトルを保存しているカラムを設定します。デフォルトではtitleが設定される
  # text_column :: 記事の本文を保存しているカラムを設定します。デフォルトではtextが設定される
  # :blog_name :: ブログ名を設定します
  module ClassMethods
    def trackback_plugin(options = {})
      has_many :trackbacks, :as => :trackable, :dependent => :destroy
          
      before_save :save_cached_trackback_list
      #      after_save :save_trackbacks
          
      include TrackbackPlugin::InstanceMethods
      extend TrackbackPlugin::SingletonMethods
      
      include TrackbackModule
      
      # オプションの解析 & 永続化
      # 値を参照するにはtrackback_plugin_options[:title_column]で
      # title_columnの場合、モデルのメソッド名になるので、それにアクセスする場合は
      # self[trackback_plugin_options[:title_column]]
      # とする
      class_inheritable_reader :trackback_plugin_options
      write_inheritable_attribute(:trackback_plugin_options,
        { :title_column  => (options[:title_column] || 'title'),
          :text_column     => (options[:text_column] || 'text'),
          :blog_name     => (options[:blog_name] || 'my blog')
        } )
    end
  end
      
  module SingletonMethods
  end
      
  module InstanceMethods
    def trackback_list
      return @trackback_list if @trackback_list
    end
        
    # TODO やっぱりvalueのtrackbackの配列は、カンマ区切りじゃなくて、そのまま配列を渡した方がいい
    # === トラックバック送信依頼を出します
    # url :: 自分の記事のURL
    # value :: トラックバック先のURLを','で区切った文字列
    def trackback_list(url, value)
      @trackback_list = TrackbackList.from(value)
      @my_url = url

      save_trackbacks
    end
    
    # === 記事に対するトラックバックを受信する。
    def post_trackback(params)
      # URL形式チェック
      # TODO: なぜ & だけ戻すのか調査
      prm_url = params[:url].gsub("%26", "&").gsub("&amp;", "&")
      #    raise "invalid url." unless url?(prm_url, article)

      # IPフィルター
      #    ip = get_ip(prm_url)
      #    raise "filtering request" unless filtering_ip(ip).empty?

      # 重複がなければ登録、重複していればスルー
      unless trackbacks.find_or_create_by_url(
          :title => params[:title],
          :url => prm_url,
          :blog_name => params[:blog_name],
          :excerpt => params[:excerpt]
          #        :ip => ip
        )
      end

      # 登録成功、もしくは登録済み
      return({:error=>"0", :message=>"OK"}.to_xml.gsub("hash", "response"))

    rescue RuntimeError, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => exc
      puts "-- tb_receive NG. port=#{request.port} -- " + exc.message
      return({:error=>"1", :message=>exc.message}.to_xml.gsub("hash", "response"))
    rescue => exc
      puts "-- tb_receive ERROR. " + exc.message
      puts exc.backtrace
      return({:error=>"1", :message=>"system error."}.to_xml.gsub("hash", "response"))
    end
  
    def save_cached_trackback_list
    end
        
    def save_trackbacks
      return unless @trackback_list
          
      new_trackback_names = @trackback_list - trackbacks.map(&:url)
          
      self.class.transaction do
        new_trackback_names.each do |new_trackback_name|
          
          # トラックバック送信
          do_tb_send(
            self[trackback_plugin_options[:title_column]],
            @my_url,
            trackback_plugin_options[:blog_name],
            self[trackback_plugin_options[:text_column]],
            new_trackback_name
          )
          
          #          trackbacks << trackbacks.find_or_create_by_url(new_trackback_name)
        end
      end
          
      true
    end
  end
end

ActiveRecord::Base.send(:include, TrackbackPlugin)
