require 'active_support'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/enumerable'
require 'action_dispatch'

class GrepRoutes
  class Rails
    def self.env
      @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development")
    end
  end
  
  attr_reader :path_to_routes_file
  attr_reader :route_file
  attr_reader :class_name
  attr_reader :pattern
  
  def initialize(path_to_routes_file)
    @path_to_routes_file = path_to_routes_file
    @route_file = File.read(path_to_routes_file)
    @class_name = route_file.match(/(\w+)::Application\.routes\.draw/)[1]
    self.init_rails_class
    self.init_rack_apps
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
    Object.const_set(class_name,Module.new) unless Object.const_defined?(class_name)
    Object.const_get(class_name,Module.new)
  end
  
  # If there are any mounted Rack apps in your routes, we'll have to grab their
  # classes and define #call on them so they look like Rack apps to the router.
  # 
  # Only the last class needs to have #call defined on it but all the objects
  # "above" it need to be defined as Modules - basically we define the object 
  # heirarchy.
  def init_rack_apps
    rack_apps = route_file.scan(/mount (.+?\s+)/).flatten.map(&:strip)
    rack_apps.each do |class_name|
      objects = class_name.split("::")
      rack_class = objects.pop
      last_object = Object
      objects.each do |obj|
         last_object.const_set(obj, Module.new) unless last_object.const_defined?(obj)
         last_object = last_object.const_get(obj)
      end
      make_rackapp(last_object, rack_class)
    end
  end
  
  def make_rackapp(mod, obj)
    mod.const_set(obj,Class.new) unless mod.const_defined?(obj)
    mod.const_get(obj,Class.new).class_eval do
      def self.call
      end
    end
  end
  
  # This evals the routes file. After this method is called the RouteSet will 
  # have all of our routes inside it.
  def eval_routes
    eval(route_file)
  end
  
  # A shortcut to the RouteSet we defined in init_rails_class.
  def route_set
    rails_app.const_get('Application', Class.new).routes
  end
  
  # Returns an Array of Hashes to make it easier to reference parts of the route.
  # This is stolen from the Rail's routes rake task.
  def routes
    return @routes if @routes
    
    @routes = route_set.routes.collect do |route|
      reqs = route.requirements.dup
      reqs[:to] = route.app unless route.app.class.name.to_s =~ /^ActionDispatch::Routing/
      reqs = reqs.empty? ? "" : reqs.inspect
      {:name => route.name.to_s, :verb => route.verb.to_s, :path => route.path, :reqs => reqs}
    end
     # Skip the route if it's internal info route
    @routes.reject! { |r| r[:path] =~ /\/rails\/info\/properties|^\/assets/ }
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
      string.gsub(pattern){|s| "\e[35m#{$1}\e[0m"} if pattern
    end
  end
  
  def print
    puts formatted_routes
  end
  
end