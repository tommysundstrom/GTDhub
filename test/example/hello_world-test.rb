#
#  HelloWorld-test.rb
#  TemplateProject
#
#  Created by Tommy Sundström on 4/3-09.
#  Copyright (c) 2009 Helt Enkelt ab. All rights reserved.
#

require 'test/unit'
require 'rubygems'
require 'shoulda'
require 'assert2'



class TC_HelloWorld_test < Test::Unit::TestCase
  def setup
    # Log.debug "Sets up a #{File.basename(__FILE__)} test."
  end

  context "Test." do
    should "Assert true." do
      assert {true}
    end
    
    #should "Deny false." do
    #  deny {false}
    #end
    
    #should "Fail this." do
    #   assert {false}
    #end
  end
end
