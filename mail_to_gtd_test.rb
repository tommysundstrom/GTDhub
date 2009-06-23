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
    @mail = Mail_app.new
    @gtd  = TheHitList_app.new
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    # Do nothing
  end

  def test_detect_if_nothing_is_selected
    assert(@mail.selection.size > 0, 'Something needs to be selected for the test.')
  end

  context "Running the application - " do
    setup do
      @controller = Controller.new
    end

    should_eventually "Create a task" do
      message_id = "200906201345.n5KDjITn001250@www16.aname.net"
      rule = "Act-On: t | Test"
      @controller.process_message_rule(message_id, mailbox_path = "INBOX", rule)
    end

    should_eventually "Create a task for a mail from Stadsbiblioteket" do
      message_id = "200806290401.m5T41Ol0000181126@begull.malmo.stadsbibliotek.org"
      rule = "Stadsbiblioteket"
      @controller.process_message_rule(message_id, mailbox_path = "INBOX", rule)
    end

    should "Create a task for a mail" do
      message_id = '0016e64618a4c69560046cb1820c@google.com'
      rule = 'Act-On: s | Svara'
      @controller.process_message_rule(message_id, mailbox_path = "INBOX", rule)
    end
  end


=begin
  context "Controller - " do
    setup do
      @controller = Controller.new
    end

    context "Creating tasks by calling the script directly - " do
      should "Create a basic task" do
        @controller.send_selected_messages_to_gtd
      end

      should "Create a task with project and context" do
        task_properties = { 'name' => 'Create a task with project and context'}
        context_path = 'Datorn'
        project_path = 'Test'
        @gtd.create_task_with_context_in_project(task_properties, context_path, project_path)
      end

      should "Create a task using the same method as when calling from the command line" do
        @controller.send_selected_messages_to_gtd
      end
    end 

    context "Utilities - " do
      should "Find context in ARGV" do
        assert(@controller.value_for_key_from_shell_arguments('context', ['--project', 'a project', '--context', 'the_context']) == 'the_context')
      end
    end
  end

  context "GTD application" do

    context "Handling contexts" do
      should "Return a context object, given a context path" do
        context_object = @gtd.context_from_path("Datorn:Kodning:Bug")
        assert(context_object.class.to_s == 'OSX::OmniFocusContext')
        assert(context_object.title == 'Bug')
      end
    end

    context "Handling projects" do

      should "Return a project or a folder, given a simple project path" do
        project_object = @gtd.project_from_path("GTD")
        assert(project_object.class.to_s == 'OSX::OmniFocusFolder' || project_object.class.to_s == 'OSX::OmniFocusProject')
        assert project_object.title == 'GTD'
      end

      should "Return a project or a folder, given a more komplex project path" do
        project_object = @gtd.project_from_path("Datordrift:Testa")
        assert(project_object.class.to_s == 'OSX::OmniFocusFolder' || project_object.class.to_s == 'OSX::OmniFocusProject')
        assert project_object.title == 'Testa'
      end

      should_eventually "Handle project paths with swedish characters" do
        project_object = @gtd.project_from_path("Datordrift/Datorskštsel")
        assert(project_object.class.to_s == 'OSX::OmniFocusFolder' || project_object.class.to_s == 'OSX::OmniFocusProject')
        assert project_object.title == 'Datorskštsel'
      end
    end

    context "Creating a task - " do
      should "Create a task (samma igen - ta bort nŠr jag vet att bŒda funkar)" do
        task_properties = { 'name' => 'Task skapad med Ruby'}
        context_path = 'Datorn'
        project_path = 'Test'
        @gtd.create_task_with_context_in_project(task_properties, context_path, project_path)        
      end
    end
  end



  def test_archiving_mail_to_root_level_mailbox
    #assert(@mail.archive_selected_messages("Test3"))   
  end

  def test_archiving_mail_to_2nd_level_mailbox
    #assert(@mail.archive_selected_messages("Bacn/Test2"))
  end

  # Fake test
  #def test_fail

    # To change this template use File | Settings | File Templates.
  #  fail("Not implemented")
  #end
=end
end