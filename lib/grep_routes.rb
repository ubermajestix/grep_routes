# See if the user has the 3.2 or 3.1 version of active_support.
# If not, blow up.
begin
  gem 'activesupport', '>= 3.1.0', '< 3.3.0'
rescue LoadError => e
  puts "You do not have activesupport ~> 3.1 installed.\nThis gem does not work with Rails 2 or 3.0"
  exit 1
end
require 'active_support'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/enumerable'
require 'active_support/inflector'
require 'grep_routes_mock_rack_app'

# See if the user has the 3.2 or 3.1 version of actionpack for action_dispatch.
# If not, blow up.
begin
  gem 'actionpack', '>= 3.1.0', '< 3.3.0'
rescue LoadError
  puts "You do not have actionpack ~> 3.1 installed.\nThis gem does not work with Rails 2 or 3.0"
  exit 1
end
require 'action_dispatch'

class GrepRoutes
  class Rails
    def self.env
      @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development")
    end
  end
  
  attr_reader :path_to_routes_file
  attr_reader :route_file
  attr_reader :rails_class
  attr_reader :pattern
  attr_reader :classes
  attr_reader :classes_with_methods
  attr_reader :eval_failures
  
  def initialize(path_to_routes_file)
    @path_to_routes_file = path_to_routes_file
    @route_file = ""
    File.open(path_to_routes_file){|f| f.each_line{|l| @route_file << l unless l.strip[0]=='#' }}
    @rails_class = route_file.match(/(\w+)::Application\.routes\.draw/)[1]
    @eval_failures = 0
    self.init_rails_class
    self.init_other_classes
  end
  
  # To make this fast we don't load your rails app or any of your gems.
  # Instead we build YourRailsApp::Application class and define one method on it.
  # The #routes method is almost the same as what Rails provides and once we eval
  # the routes file, it will be filled up with your routes.
  def init_rails_class
    rails_app.module_eval do
      self.const_set('Application', Class.new) unless self.const_defined?('Application')
      self.const_get('Application', Class.new).class_eval do
        def self.routes
          @routes ||= ActionDispatch::Routing::RouteSet.new
        end
      end
    end
  end
  
  def rails_app
    Object.const_set(rails_class,Module.new) unless Object.const_defined?(rails_class)
    Object.const_get(rails_class,Module.new)
  end
  
  def init_other_classes
    find_classes
    find_classes_with_methods
    classes.each do |class_name|
      define_objects(class_name)
    end
    # This is causing problems: 'Stack level too deep' during eval, the retry will
    # catch any undefined methods and define them on the right class
    # classes_with_methods.each do |class_and_method|
    #     # define_methods(*class_and_method)
    #   end
  end
  
  def find_classes
    @classes = route_file.scan(/([A-Z][a-zA-Z0-9::]*)/).flatten.reject{|c| c.match(rails_class) || c.match("Rails") }
  end
  
  def find_classes_with_methods
    match = route_file.scan(/([A-Z][a-zA-Z0-9::]*)\.([_a-z]+[_a-z0-9_<>=~@\[\]]*[=!\?]?)/)
    match.reject!{|m| m.first.match(rails_class) || m.first.match("Rails") }
    # parse out the first method if there's a chain
    # TODO deal with method chains like `app.rack.server`
    match.each{|m| m[1] = m.last.split(".").first}
    @classes_with_methods = match
  end
  
  def define_objects(class_name)
    objects = class_name.split("::")
    rack_class = objects.pop
    last_object = Object
    objects.each do |obj|
       last_object.const_set(obj, Module.new) unless last_object.const_defined?(obj)
       last_object = last_object.const_get(obj)
    end
    make_rackapp(last_object, rack_class)
  end
  
  # TODO there has got to be a better way to do this!
  def define_methods(class_name, method_name)
    class_name.constantize.class_eval do
      method_to_eval = <<-method_to_eval
      def self.#{method_name}
        GrepRoutesMockRackApp.new
      end
      method_to_eval
      eval(method_to_eval)
    end
  end
  
  def make_rackapp(mod, obj)
    mod.const_set(obj,GrepRoutesMockRackApp) unless mod.const_defined?(obj)
  end
  
  # This evals the routes file. After this method is called the RouteSet will 
  # have all of our routes inside it.
  def eval_routes
    begin
      eval(route_file)
    # If a method is not defined on a class, we define it and try again
    rescue NoMethodError => e
      @eval_failures += 1
      match = e.message.match(/undefined method `(.+)' for (.+):Class/)
      undefined_method = match[1]
      define_methods(match[2], undefined_method)
      retry
    # If a class is not defined we define it and try again
    rescue NameError => e
      @eval_failures += 1
      class_name = e.message.match(/uninitialized constant (.+)$/)[1].gsub("GrepRoutes::", '')
      define_objects(class_name)
      retry
    end
  end
  
  # A shortcut to the RouteSet we defined in init_rails_class.
  def route_set
    rails_app.const_get('Application', Class.new).routes
  end
  
  # Returns an Array of Hashes to make it easier to reference parts of the route.
  # This is stolen from the Rail's 3.2 RouteFormatter
  def routes
    return @routes if @routes
    
    @routes = route_set.routes.collect do |route|
      route_reqs = route.requirements

      controller = route_reqs[:controller] || ':controller'
      action     = route_reqs[:action]     || ':action'

      # TODO figure out how they're doing this engine/rackapp routeing stuff.
      # rack_app = discover_rack_app(route.app)
      # endpoint = rack_app ? rack_app.inspect : "#{controller}##{action}"
      endpoint = "#{controller}##{action}"
      constraints = route_reqs.except(:controller, :action)

      reqs = endpoint
      reqs += " #{constraints.inspect}" unless constraints.empty?
        
      if route.verb.respond_to?(:source)
        verb = route.verb.source.gsub(/[$^]/, '')
      else
        verb = route.verb
      end
      
      if route.path.respond_to?(:spec)
        path = route.path.spec.to_s
      else
        path = route.path
      end
      
      # collect_engine_routes(reqs, rack_app)

      {:name => route.name.to_s, :verb => verb, :path => path, :reqs => reqs }
    end
     # Skip the route if it's internal info route
    @routes. reject! { |r| r[:path] =~ /\/rails\/info\/properties|^\/assets/ }
    return @routes
  end
  
  # This method filters the routes by matching the basic route string that will 
  # outputted against a string or regex.
  # 
  # You should call this method before formatted_routes so that the offsets will 
  # only apply to the filtered routes. Otherwise you'll have really weird output
  # like when you run `rake routes | grep somepattern`. 
  def filter_routes(pattern)
    @pattern = Regexp.new pattern
    @routes = routes.select{|r| "#{r[:name]} #{r[:verb]} #{r[:path]} #{r[:reqs]}".match pattern}
    @routes
  end
  
  # This formats the route as an Array of Strings.
  # This is stolen from the Rail's routes rake task.
  def formatted_routes
    name_width = routes.map{ |r| r[:name].length }.max
    verb_width = routes.map{ |r| r[:verb].length }.max
    path_width = routes.map{ |r| r[:path].length }.max
    routes.collect do |r|
      string = "#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:path].ljust(path_width)} #{r[:reqs]}"
      string.gsub!(pattern){|s| "\e[35m#{s}\e[0m"} if pattern
      string
    end
  end
  
  def print
    puts formatted_routes
  end
  
end