#
#  test_setup.rb
#  FlatTemplate
#
#  Created by Tommy Sundström on 12/3-09.
#  Copyright (c) 2009 Helt Enkelt ab. All rights reserved.
#

require 'test/unit'
require 'rubygems'
require 'shoulda'
require 'assert2'

# Has effect when using 'rake test'. Makes the environment simular to when running the classes
#     (among other things, it loads $log)
#     Since rb_main_init requires *all* rb-files, and since this (as I understand it) runs for
#     every test case, it can make testing slow.
  #require 'rb_main'
  #rb_main_init

