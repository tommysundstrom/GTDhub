#
#  HelloWorld.rb
#  TemplateProject
#
#  Created by Tommy Sundström on 4/3-09.
#  Copyright (c) 2009 Helt Enkelt ab. All rights reserved.
#

require 'osx/cocoa'
#require '../standardutilities/log'

class HelloWorld
  def initialize
    Log.info "Hello World"
  end
end

hw = HelloWorld.new


