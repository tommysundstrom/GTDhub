#
#  Log-test.rb
#  FlatTemplate
#
#  Created by Tommy Sundström on 12/3-09.
#  Copyright (c) 2009 Helt Enkelt ab. All rights reserved.
#

require 'test_setup'
require 'log'
require 'tommys_utilities'

# Pathstring('~/Library/Logs/Ruby/FlatTemplate/_info-rolling-000001.log').expand_path


class TC_Log_test < Test::Unit::TestCase

  context "Log --" do
  
    context "Debug log. Log.level 'Message' --" do    
      should "Log in the form Log.debug 'message'." do
        assert_nothing_raised { Log.debug "Log.debug message" }
        assert { Log.message_in_last_line_of_log(Pathstring('~/Library/Logs/Ruby/«PROJECTNAME»/_all.log').expand_path) == "[DEBUG] Log.debug message" }
      end      
    end
    
    context "Create log object. log = Log.new(something) --" do
      context "Log created for the current file --" do
      
        setup do
          @local_log = Log.new(__FILE__) 
        end
        
        should "Create a log for the current file." do
          assert_nothing_raised { log = Log.new(__FILE__) }
        end
        
        should "Log to a current file log." do
          assert_nothing_raised { @local_log.debug "debug on a log crated with #{__FILE__}" }
        end
        
        should "Log to all levels." do
          assert_nothing_raised { @local_log.debug "Log.debug to a log crated with #{__FILE__}" }
          assert_nothing_raised { @local_log.info  "Log.info  to a log crated with #{__FILE__}" }
          assert_nothing_raised { @local_log.warn  "Log.warn to a log crated with #{__FILE__}" }
          assert_nothing_raised { @local_log.error "Log.error to a log crated with #{__FILE__}" }
          assert_nothing_raised { @local_log.fatal "Log.fatal to a log crated with #{__FILE__}" }
        end
        
        should "Log warnings also to the warnings & errors log." do
          @local_log.warn  "Log.warn to a log crated with #{__FILE__}"
          assert { File.exist?(Pathstring('~/Library/Logs/Ruby/«PROJECTNAME»/WARNINGS & ERRORS.log').expand_path) }
          assert { Log.message_in_last_line_of_log('/Users/Tommy/Library/Logs/Ruby/«PROJECTNAME»/WARNINGS & ERRORS.log') == "[ WARN] Log.warn to a log crated with ./log-test.rb" }
        end
      end # /context "Log created for the current file --" do
      
      context "Log created with a name --" do
        setup do
          @local_log = Log.new('A name for the log') 
        end
        
        should "Create a named log." do
          assert { @local_log.class == Log }
        end
        
        should "Log to a named log." do
          assert_nothing_raised { @local_log.debug "Log.debug to a named log" }
        end
      end # /context "Log created with a name --" do    
      
    end # /context "Create log object. log = Log.new(something) --" do
          
    context "Class as log. Log.debug Message --" do
      context "Log created for the current file --" do
        setup do
          @local_log = Log.new(__FILE__) 
        end
        
        should "Create a log for the current file." do
          assert { @local_log.class == Log }
        end
        
        should "Log to a current file log." do
          assert_nothing_raised { Log.debug "Log.debug - class used as log." }
        end
      end # /context "Log created for the current file --" do  
    end # /context "Class as log. Log.debug 'Message' --" do  
  end # /context "Log --" do  
end # /class Log_test
