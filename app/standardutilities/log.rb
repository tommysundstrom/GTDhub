#
#  Log.rb
#  FlatTemplate
#
#  Created by Tommy Sundström on 12/3-09.
#  Copyright (c) 2009 Helt Enkelt ab. All rights reserved.
#

require 'osx/cocoa'
require 'pathstring'
require 'rubygems'
require 'log4r'


# When this source file is loaded, it cleans out old logs.
  APPLICATION_NAME = Pathstring.new(__FILE__).application_name  # Code here is same as used inside class
  LOG_DIRECTORY = Pathstring("~/Library/Logs/Ruby/#{APPLICATION_NAME}").expand_path 
  LOG_DIRECTORY.mkpath # Makes sure the path exists
  
  logdir = Pathstring(LOG_DIRECTORY)
  logdir.children.each do |file| 
    unless Pathstring(file).basename.scan(/rolling/)[0] # Note: This depends on the convention to include 'rolling' in the name of persistent files. TODO: Remove older rolling logs.
      # If it is not a persistent log
      #   remove it
      puts "Removing log: #{file.basename}"
      file.unlink
    end
  end

# Log
#
# Singelton class
#
# Usage: 
# require 'log'
# Log.debug "message"
#
# Important: This class can both be used as it is Log.debug 'message' and
# to produce separate log objects.
#
# Can be used both directly (Log.debug "Message")
# and to produce logs, local_log = Log(__FILE__) 
# or Log(__FILE__).debug "Message"
class Log #< OSX::NSObject
  include Log4r
  
  # Constants
    APPLICATION_NAME = Pathstring.new(__FILE__).application_name    
    FORMATTER = PatternFormatter.new(:pattern => "%d [%5l] %m")  # Format for log entries
    ROLLOVER_TIME = 60*60*24    # 24 h in seconds.
    ROLLOVER_SIZE = 100000
    # TODO: Should remove session logs from previous sessions (on class initiation or in setup)
    LOG_DIRECTORY = Pathstring("~/Library/Logs/Ruby/#{APPLICATION_NAME}").expand_path 
    LOG_DIRECTORY.mkpath # Makes sure the path exists
    
  # Class variables
    @@logs = {}
  
  

  
  def initialize(logname = :default)  # (Normaly logname is a string. Tip: use __FILE__.)
    @logname = logname
    unless @@logs.has_key?(@logname)  # If there is alread a log with the name, use it
      setup_log
      setup_default if @logname == :default 
    end
  end
  
  def setup_log
    return if @@logs.has_key?(@logname)   # Log with this name already created and will be used.
    
    # OSX::NSLog("logname: #{@logname}")
    if @logname == :default
      log = Logger.new('default')
    else
      log = Logger.new(@logname)
    end
    
    # General output, a session log that collects all. TODO: Change format 
          # so that it's possible to see what log has written what.
      log.outputters << FileOutputter.new('output_all', :filename => (LOG_DIRECTORY + "_all.log").to_s, :formatter => FORMATTER) 
      
    # General warnings. A warnings and errors log that all logs are writing to
      log.outputters << FileOutputter.new('output_warn', :filename => (LOG_DIRECTORY + "WARNINGS & ERRORS.log").to_s, :formatter => FORMATTER, :level => WARN )
      
    #log.outputters.each{|t| puts t.name}  # TEST
      
    # This log only.
      log.outputters << file_outputter
      
    # Send result also to stdout  TODO: Remove from unit test runs
    #  std = Outputter.stdout
    #  std.formatter = PatternFormatter.new(:pattern => "[%5l] %c :: %m")
    #  log.outputters << Outputter.stdout 
    
    # Save in class repository
      @@logs[@logname] = log   
  end
  
  def setup_default
    # Info output. Just the info messages from this log
      outputter = file_outputter
      outputter.level = INFO
    
    # Rolling log with INFO+
      @@logs[:default].outputters << RollingFileOutputter.new('output_rolling_info', :filename => (LOG_DIRECTORY + "_info-rolling-.log").to_s, :trunc => false, :formatter => FORMATTER, :maxsize => ROLLOVER_SIZE, :level => INFO )
      (LOG_DIRECTORY + "_info-rolling-.log").unlink     # Remove empty log (created but not used, as some kind of sideffect of 'maxsize')
  end

  # Outputters doc: http://log4r.sourceforge.net/rdoc/files/log4r/outputter/outputter_rb.html
    def file_outputter
      if @logname == :default
        id = ''
        filename = '_all'
      else
        id = "_#{@logname}"
        filename = @logname
      end
      
      return FileOutputter.new("output_all#{id}", :filename => (LOG_DIRECTORY + "#{filename}.log").to_s, :formatter => FORMATTER) 
    end
      
  
  # Helper for Level-methods
  def Log.ensure_default_log
    Log.new(:default) unless @@logs.has_key?(:default)
  end

  # Level-methods
  def Log.debug(msg)
    Log.ensure_default_log
    @@logs[:default].debug(msg)
  end
  
  def Log.info(msg)
    Log.ensure_default_log
    @@logs[:default].info(msg)
  end
  
  def Log.warn(msg)
    Log.ensure_default_log
    @@logs[:default].warn(msg)
  end
  
  def Log.error(msg)
    Log.ensure_default_log
    @@logs[:default].error(msg)
  end
  
  def Log.fatal(msg)
    Log.ensure_default_log
    @@logs[:default].fatal(msg)
  end
  

  
  def debug(msg)
    @@logs[@logname].debug(msg)
  end
  
  def info(msg)
    @@logs[@logname].info(msg)
  end
  
  def warn(msg)
    @@logs[@logname].warn(msg)
  end
  
  def error(msg)
    @@logs[@logname].error(msg)
  end
  
  def fatal(msg)
    @@logs[@logname].fatal(msg)
  end 
  
  
  def get_log_object
    @@logs[:default]
  end
  
  # Extracts the message from the last log-line.
  # Primarily used for testing
  # TODO: Change to instance method, using conventional ways of identifying the log.
  require 'tommys_utilities'
  def Log.message_in_last_line_of_log(path)
    return Tommys_utilities::last_line_of_file(path).scan(/\[.*/)[0]
  end
  
end



