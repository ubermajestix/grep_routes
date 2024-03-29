require 'spec_helper'

describe GrepRoutes do
  subject do
    GrepRoutes.new('spec/fixtures/routes.rb')
  end
  
  it "should set the path to the routes file as an instance var" do
    subject.path_to_routes_file.must_equal 'spec/fixtures/routes.rb'
  end
  
  it "should define the rails application class from the routes file" do
    subject.rails_app.to_s.must_equal 'SomeRailsApp'
  end
  
  it "should have a shortcut to the RouteSet" do
    subject.route_set.must_be_kind_of ActionDispatch::Routing::RouteSet
  end
  
  it "there should be routes after we eval the routes file" do
    subject.eval_routes
    subject.route_set.routes.length.must_be :>, 1
  end
  
  it "should filter routes" do
    subject.eval_routes
    subject.filter_routes('privacy')
    subject.routes.length.must_equal 1
  end
  
  it "should filter routes using a regex" do
    subject.eval_routes
    subject.filter_routes('(privacy|terms)')
    subject.routes.length.must_equal 2
  end
  
  it "should have a bunch of routes" do
    subject.eval_routes
    subject.routes.length.must_equal 72
    
  end
end