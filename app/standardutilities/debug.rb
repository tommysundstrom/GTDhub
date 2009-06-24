#
#  Debug.rb
#  ItunesFeeder
#
#  Created by Tommy Sundström on 3/3-09.
#  Copyright (c) 2009 Helt Enkelt ab. All rights reserved.
#

module Debug # Usage: http://snippets.dzone.com/posts/show/6978
  def whoAmI?
    "#{self.type.name} (\##{self.id}): #{self.to_s}"
  end
end



