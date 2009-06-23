require 'test/unit'
require 'rubygems'
require 'shoulda'
require 'assert2'
# TODO: logg
require 'mail_to_gtd'


class MailToGtdTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    # Do nothing
  end

  context "Run from shell - " do
    should "Do this shell command" do
      %x[ruby "/Users/Tommy/Programmering/Ruby/RubymineProjects/mail_to_gtd/mail_to_gtd.rb" "200906201345.n5KDjITn001250@www16.aname.net|Act-On: t | Test"]
    end
  end

=begin
  context "Controller - " do
    setup do
    end

    context "Creating tasks via command line - " do
      should "Create a task, using the command line" do
        puts "sh: ruby mail_to_gtd.rb"
        %x[ruby mail_to_gtd.rb]
      end
      
      should "Create a task with the --project parameter" do
        puts "sh: ruby mail_to_gtd.rb --project Test2"
        %x[ruby mail_to_gtd.rb --project Test2 ]
      end

      should "Create a task with the --project and --context parameters" do
        puts "sh: ruby mail_to_gtd.rb --project Test2 --context Datorn"
        %x[ruby mail_to_gtd.rb --project Test2 --context Datorn ]
      end

      should "Create a task in a sub-project" do
        puts "sh: ruby mail_to_gtd.rb --project Kunder:Factlab --context Hemma"
        %x[ruby mail_to_gtd.rb --project Kunder:Factlab --context Hemma  ]
      end

      should "Create a task in a sub-context" do
        puts "sh: ruby mail_to_gtd.rb --project Kunder:Factlab --context Datorn:Fakturering"
        %x[ruby mail_to_gtd.rb --project Kunder:Factlab --context Datorn:Fakturering  ]
      end

      should "Create a task with Swedish chars in the --project parameter" do
        puts "sh: ruby mail_to_gtd.rb --project Datordrift:Datorskštsel "
        %x[ruby mail_to_gtd.rb --project Datordrift:Datorskštsel ]
      end

      should "Create a task with the name controlled by --title" do
        puts "sh: ruby mail_to_gtd.rb --title Name_from_dash_name"
        %x[ruby mail_to_gtd.rb --title Name_from_dash_name ]
      end

      should "Create a task with a quoted name in --title" do
        puts "sh: ruby mail_to_gtd.rb --title 'Quoted name' "
        %x[ruby mail_to_gtd.rb --title 'Quoted name' ]
      end
    end
  end
=end
 
end