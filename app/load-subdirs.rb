#---
# Excerpted from "RubyCocoa",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/bmrc for more book information.
#---

#rbfiles = Dir.chdir(app_root) { Dir["*.rb"] }
#rbfiles.each { |file| require(file) }


Dir.chdir(File.dirname(__FILE__)) do
  Dir.pwd.each do |item|
    if File.directory?(item)
      Dir.chdir(item) do
        Dir[File.basename(item) + '/*.rb'].each { | file | require file}
      end
    end
    #TODO if load-subdirs
  end
end

=begin
Dir.chdir(File.dirname(__FILE__)) do
  Dir['**/*.rb'].each { |file|
    puts File.join('../app', file[0...-3])
    require(File.join('../app', file[0...-3]))    # (Drops the '.rb')'
  }   # Recursivly require any file in this directory
end
=end


=begin
# Original code
Dir.chdir(File.dirname(__FILE__)) do
  Dir['util/*.rb'].each { | file | require file }
  Dir['preferences/*.rb'].each { | file | require file }
  Dir['translators/*.rb'].each { | file | require file }
  Dir['main-window/*.rb'].each { | file | require file }
  Dir['prefs-window/*.rb'].each { | file | require file }
end
=end

