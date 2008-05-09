# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

module TrackbackModule
  
#  include ActionView::Helpers::TextHelper
  require "rexml/document"
  require 'net/http'
  require "socket"
  
  # === 相手の記事へトラックバックを貼る。（実際の通信部分）
  # title :: 記事のタイトル
  # url   :: 記事のURL
  # blog_name :: ブログの名前
  # excerpt :: 記事の詳細の先頭から100文字程度
  # trackback_url :: 相手のトラックバックURL
  def do_tb_send(title, url, blog_name, excerpt, trackback_url)
    uri = URI.parse trackback_url
    query = ''
    query = uri.query.to_s
    query << '&' if query && query.size > 0
    query << "title=#{CGI.escape(title)}&url=#{CGI.escape(url)}&blog_name=#{CGI.escape(blog_name)}&excerpt=#{CGI.escape(excerpt)}"
    header = {'Content-Type' => 'application/x-www-form-urlencoded'}

    Net::HTTP.start(uri.host, uri.port) do |http|
      response,body = http.post(uri.path, query, header)
      doc = (REXML::Document.new body).root
      val = REXML::XPath.first(doc, 'child::error')
      if val
        return val.text
      end
    end
    return '1'
  rescue URI::InvalidURIError, Timeout::Error => exc
    puts '-- do_tb_send NG -- ' + exc.message
    return '1'
  end
  
end
