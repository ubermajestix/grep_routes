require 'spec_helper'

describe GrepRoutes do
  
  subject do
    GrepRoutes.new('spec/fixtures/routes_with_rack_mounts.rb')
  end
  
  it "should handle mounted Rack apps" do
    subject.init_rack_apps
    subject.eval_routes
    subject.routes.length.must_equal 6
  end
  
  it "should print the rack app routes" do
    subject.init_rack_apps
    subject.eval_routes
    subject.print
  end
end