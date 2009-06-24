#
# Copyright (c) 2006 Martin Traverso, Brian McCallister
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Documentation: http://split-s.blogspot.com/2006/02/design-by-contract-for-ruby.html
 
module DesignByContract
	@@pending = Hash.new { |hash, key| hash[key] = {} }
	
	private 

	def self.extract(this, method_name, message)
		if method_name.respond_to?(:to_str)
			# no method symbol specified, just the message
			message = method_name
			method_name = nil
		elsif !method_name.nil? && this.method_defined?(method_name)
			old_method = this.instance_method(method_name) 
		end

		return old_method, method_name, message
	end
	
	def self.schedule(type, mod, method_name, message, condition)
		@@pending[mod][method_name] ||= []
		@@pending[mod][method_name] << {:type => type, :message => message, :condition => condition}
	end

	def self.included(mod)
		old_method_added = mod.method :method_added

		new_method_added = lambda { |id| 			
			if @@pending.has_key? mod
				# save the list of methods and clear the entry
				# otherwise, we'll have infinite recursion on the call to mod.send(...)
				hooks = @@pending[mod].values_at(id, nil).compact.flatten
				@@pending[mod].delete id
				@@pending[mod].delete nil

				# define scheduled hooks
				hooks.each do |entry|
					mod.send entry[:type], id, entry[:message], &entry[:condition]
				end
			end
			
			old_method_added.call id
		}
		
		(class << mod; self; end).send :define_method, :method_added, new_method_added
		
		class << mod
			def pre(method_name = nil, message = nil, &condition)
				old_method, method_name, message = DesignByContract.extract self, method_name, message

				unless old_method.nil?
					# make a method out of the condition so that we can bind it against self
					# and pass it the arguments (it'd be easier if instance_eval accepted arguments...)
					define_method(method_name, &condition)
					condition_method = instance_method(method_name)
					define_method(method_name) { |*args|
						unless condition_method.bind(self).call(*args)
							raise "Pre-condition #{'\'' + message + '\' ' if message}failed"
						end

						old_method.bind(self).call(*args)
					}
				else
					DesignByContract.schedule :pre, self, method_name, message, condition 
				end
			end

			def post(method_name = nil, message = nil, &condition)
				old_method, method_name, message = DesignByContract.extract self, method_name, message

				unless old_method.nil?
					# make a method out of the condition so that we can bind it against self
					# and pass it the arguments (it'd be easier if instance_eval accepted arguments...)
					define_method(method_name, &condition)
					condition_method = instance_method(method_name)
					define_method(method_name) { |*args|
						result = old_method.bind(self).call(*args)
						unless condition_method.bind(self).call(result, *args)
							raise "Post-condition #{'\'' + message + '\' ' if message}failed" 
						end
						return result
					}
				else
					DesignByContract.schedule :post, self, method_name, message, condition 
				end
			end
		end
	end
end

if $0 == __FILE__
	require 'test/unit'

	class TestDBC < Test::Unit::TestCase
		def test_instance_vars
			c = Class.new {
				include DesignByContract

				def initialize
					@v = 1
				end

				pre { @v == 1 }
				def method_1
				end

				post { @v == 1 }
				def method_2
				end

				pre { @v == 2 }
				def method_3
				end

				post { @v == 2 }
				def method_4
				end
			}	

			assert_nothing_raised { c.new.method_1 }
			assert_nothing_raised { c.new.method_2 }
			assert_raise(RuntimeError) { c.new.method_3 }
			assert_raise(RuntimeError) { c.new.method_4 }
		end


		def test_pre_explicit
			c = Class.new {
				include DesignByContract
			
				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				pre(:method_1) { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(!o.method_1_called)
		end

		def test_post_explicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				post(:method_1) { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
		end


		def test_pre_and_post_explicit
			c = Class.new {
				include DesignByContract
		
				attr_reader :method_1_called
				attr_reader :method_2_called

				def initialize
					@method_1_called = false
					@method_2_called = false
				end

				pre(:method_1) { true }
				post(:method_1) { false }
				def method_1
					@method_1_called = true
				end

				pre(:method_2) { false }
				post(:method_2) { true }
				def method_2
					@method_2_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
			assert_raise(RuntimeError) { o.method_2 }
			assert(!o.method_2_called)
		end


		def test_multi_post_explicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				post(:method_1) { true }
				post(:method_1) { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
		end

		def test_multi_pre_explicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				pre(:method_1) { true }
				pre(:method_1) { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(!o.method_1_called)
		end


		def test_pre_implicit
			c = Class.new {
				include DesignByContract
			
				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				pre { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(!o.method_1_called)
		end

		def test_post_implicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				post { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
		end


		def test_pre_and_post_implicit
			c = Class.new {
				include DesignByContract
		
				attr_reader :method_1_called
				attr_reader :method_2_called

				def initialize
					@method_1_called = false
					@method_2_called = false
				end

				pre { true }
				post { false }
				def method_1
					@method_1_called = true
				end

				pre { false }
				post { true }
				def method_2
					@method_2_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
			assert_raise(RuntimeError) { o.method_2 }
			assert(!o.method_2_called)
		end


		def test_multi_post_implicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				post { true }
				post { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
		end

		def test_multi_pre_implicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				pre { true }
				pre { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(!o.method_1_called)
		end


		def test_pre_implicit
			c = Class.new {
				include DesignByContract
			
				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				pre { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(!o.method_1_called)
		end

		def test_post_implicit
			c = Class.new {
				include DesignByContract

				attr_reader :method_1_called

				def initialize
					@method_1_called = false
				end

				post { false }
				def method_1
					@method_1_called = true
				end
			}	

			o = c.new
			assert_raise(RuntimeError) { o.method_1 }
			assert(o.method_1_called)
		end

	end
end