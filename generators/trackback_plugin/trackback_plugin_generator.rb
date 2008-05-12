#require 'delegate'
#require 'optparse'
#require 'fileutils'
#require 'tempfile'
#require 'erb'

class TrackbackPluginGenerator < Rails::Generator::NamedBase
  
  attr_reader :controller_name, :controller_class_path, :controller_file_path, :controller_class_nesting, :controller_class_nesting_depth,
  :controller_class_name, :controller_singular_name, :controller_plural_name
  alias_method  :controller_file_name,  :controller_singular_name
  alias_method  :controller_table_name, :controller_plural_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    
    # Take controller name from the next argument.  Default to the pluralized model name.
    @controller_name = args.shift
    @controller_name ||= ActiveRecord::Base.pluralize_table_names ? @name.pluralize : @name
    
    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_singular_name, @controller_plural_name = inflect_names(base_name)
    
    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end
  
  def manifest 
    record do |m|
      # コントローラ名が衝突していないことを確認
      m.class_collisions "#{controller_class_name}Controller"
      
      # コントローラのフォルダを作成
      m.directory File.join('app/controllers', controller_class_path)
      
      # trackbackアクションを追加
      add_trackback_action(m)
      
      # routes.rbを設定
      route_resources controller_file_name
    end 
  end
  
  def file_name
    'trackback_plugin'
  end
  
  protected
  # Override with your own usage banner.
  def banner
      "Usage: #{$0} trackback_plugin ModelName [ControllerName]"
  end
  
  def add_trackback_action(m)
    
    if File.exists?(File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb"))
      sentinel = "class #{controller_class_name}Controller < ApplicationController"
      
      p sentinel
      gsub_file File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb"), /(#{Regexp.escape(sentinel)})/mi do |match|
<<EOS
#{match}

  protect_from_forgery :except => :trackback
  
  # === トラックバックを受け付けるアクションです
  def trackback
    
    # 記事を特定
    article = Article.find(params[:id])
    
    # 内部でparamsを解析
    render :xml => article.post_trackback(params)
  end
EOS
      end
    else
      # コントローラを配置
      m.template 'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
    end
    
  end
  
  
  def route_resources(resource)
    resource = resource.to_sym.inspect
    sentinel = 'ActionController::Routing::Routes.draw do |map|'
    
    logger.route "map.resources #{resource}, :member => {:trackback => :post}"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
              "#{match}\n  map.resources #{resource}, :member => {:trackback => :post}\n"
      end
    end
  end
  
  def gsub_file(relative_destination, regexp, *args, &block)
    path = destination_path(relative_destination)
    content = File.read(path).gsub(regexp, *args, &block)
    File.open(path, 'wb') { |file| file.write(content) }
  end
end
