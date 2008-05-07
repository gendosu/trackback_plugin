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
      
      # コントローラを配置
      m.template 'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      
      m.route_resources controller_file_name
    end 
  end
  
  def file_name
    "trackback_plugin"
  end
  
  protected
  # Override with your own usage banner.
  def banner
      "Usage: #{$0} trackback_plugin ModelName [ControllerName]"
  end
end
