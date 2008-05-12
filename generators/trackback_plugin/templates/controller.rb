class <%= controller_class_name %>Controller < ApplicationController

  protect_from_forgery :except => :trackback
  
  # === トラックバックを受け付けるアクションです
  def trackback
    
    # 記事を特定
    article = Article.find(params[:id])
    
    # 内部でparamsを解析
    render :xml => article.post_trackback(params)
  end
end
