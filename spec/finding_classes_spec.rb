require 'spec_helper'

describe 'finding classes in routes file' do
  subject do
    # The initialization loades up classes and classes_with_methods
    GrepRoutes.new('./spec/fixtures/routes_with_two_classes.rb')
  end
  
  it "should find two classes excluding the Rails application class" do
    subject.classes.length.must_equal 2
  end
  
  it "should find one class that has a method defined on it" do
    subject.classes_with_methods.length.must_equal 1 
  end
  
  it "curiously has to define methods on GrepRoutesMockRackApp" do
    subject.eval_routes
    subject.eval_failures.must_equal 1
  end
end