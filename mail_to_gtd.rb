# Command line app, primarily used by Mail.app rules to send actions to OmniFocus
#
# To call from a rule, make an applescript like this:
=begin rdoc
  using terms from application "Mail"
      on perform mail action with messages theMessages for rule theRule
          repeat with aMessage in theMessages
              do shell script "ruby \"/Users/Tommy/Programmering/Ruby/RubymineProjects/mail_to_gtd/mail_to_gtd.rb\" \"--id " & id of aMessage & " --rule '" & name of theRule & "'\""
              -- The shell script will be something like this: 
              --
              -- ruby "/Users/Tommy/Programmering/Ruby/RubymineProjects/mail_to_gtd/mail_to_gtd.rb" "--id 48594 --rule 'Act-On: g | GTD'"
              --
              -- You may want to change this, depending on how you've set up your system.
              -- Not that no changes needs to be done to this script, once you have the right path etc. in it.
              -- Just call it from the rule.
              --
              -- Please note that if the message is moved before Ruby has been able to find it, there is a risk that it
              -- is found. So move it before the script is called, or let Ruby (not the mail filter) handle archiving,
              -- deleting, etc.


  It's up to the Ruby script to decide what should happen, depending on the name of the rule.
              -- If the message are to be moved/archived/deleted after being processed, this could be handlad by the Ruby script. Personaly I prefer to handle those things with the rule in Mail (i.e. first call this apple script, and then do the moving/deliting).
          end repeat
      end perform mail action with messages
  end using terms from
=end

require 'rubygems'
require 'osx/cocoa'
include OSX
OSX.require_framework 'ScriptingBridge'
require 'ostruct'
require 'open3' # http://tech.natemurray.com/2007/03/ruby-shell-commands.html
require 'trollop'  

class Controller
  attr_accessor :task_template

  def initialize
    @mail = Mail_app.new
    #@gtd = OmniFocus_app.new
    @gtd = TheHitList_app.new
    #@options = command_line_options(ARGV) # Dictionary with the options

=begin
    # (This is for command line. Not sure if I'm going to keep it)
    @options = Trollop::options do     # (Trollop documentation: http://trollop.rubyforge.org/ )
      opt :title, "Name of the task. If not specified, message subject is used.", :type => String
      opt :project, "The project to add the task to.", :type => String
      opt :context, "The context the task is to be performed in.", :type => String
    end

    @task_template = OpenStruct.new   # Used to keep all known common info about the task(s)
=end
  end

  def process_message_rule(message_id, mailbox_path, rule)
    NSLog "Mailbox name: " + mailbox_path
    # (Note: Only one message at the time will be feeded this way.)
    task_info = OpenStruct.new

    message = @mail.message_from_messageid(message_id, mailbox_path)

    NSLog "Processing mail rule '#{rule}' on '#{message.subject}'."
    case rule
      when 'Test'
        task_info.title = message.subject
        task_info.message_url = message_url(message_id)

      when 'Act-On: q | Agera', 'gtd@heltenkelt.se', '---'
        task_info.title = message.subject
        task_info.message_url = message_url(message_id)
        task_info.notes = message.content.get

      when 'Twitter-foljare'
        task_info.title = message.subject
        task_info.message_url = message_url(message_id)
        task_info.due_date = DateTime.parse(message.dateSent.to_s) + 14 # Two weeks from when the mail was sent.
        task_info.notes = message.content.get   # TODO Extract the right folow-url directly
        # TODO Move to a Twitter-list

      when 'Stadsbiblioteket'
        task_info.title = "Biblioteket. L√§mna: [#{message.subject}]"
        task_info.message_url = message_url(message_id)
        task_info.due_date = DateTime.parse(message.dateSent.to_s) + 2 # Two days from when the mail was sent.
        task_info.notes = message.content.get
        #@mail.archive_mailmessage(message, 'Bacn/Test2')

      when 'Act-On: s | Svara', 'Act-On: t | Test'
        task_info.title = message.subject
        task_info.contexts_tags = '@mail'
        task_info.message_url = message_url(message_id)
        task_info.due_date = DateTime.parse(message.dateSent.to_s) + 2 # Two days from when the mail was sent.
        task_info.notes = message.content.get
      
      else
        raise "No code for processing rule '#{rule}' "
    end
    @gtd.create_task(task_info)
  end

  def message_url(message_id)
    # set _messageURL to "message://%3c" & msg's message id & "%3e"
    return "message://%3c#{message_id}%3e"
  end

  def add_days_to_date(date, number_of_days)
    return
    date = message.dateSent
  end

=begin
  def create_tasks_from_selected_messages(task_template = @task_template)
    @mail.selection.each do |message|
      task_info = task_template.clone
      @gtd.create_task(task_info, message)
    end
  end


  def send_selected_messages_to_gtd
    @mail.selection.each do |message|
      task_properties = {}
      task_properties['name'] = (@options[:title] or message.subject)
      context_path = (@options[:context] or '')
      project_path = (@options[:project] or '')
      @gtd.create_task_with_context_in_project(task_properties, context_path, project_path)
    end
  end
=end
  
end

# Wrapper for 'The Hit List' application.
class TheHitList_app
  def initialize
    # Some code to remove the strange errors produced when using SBApplication.applicationWithBundleIdentifier
    # from http://www.dribin.org/dave/blog/archives/2008/05/27/sb_warnings/
    old_stderr = $stderr.clone        # save current STDERR IO instance
    $stderr.reopen('/dev/null', 'w')  # send STDERR to /dev/null
    @app = SBApplication.applicationWithBundleIdentifier('com.potionfactory.TheHitList')
    $stderr.reopen(old_stderr)        # revert to default behavior
    old_stderr.close  
  end

  def create_task(task_info)
    task_properties = {}

    # Prepare the parts of task info that are to be in the properties of the task.
    title = task_info.title if task_info.title
    title = title + ' ' + task_info.contexts_tags if task_info.contexts_tags
    task_properties['title'] = title
    task_properties['notes'] = ''
    task_properties['notes'] << task_info.message_url if task_info.message_url
    task_properties['notes'] << "\n\n" if task_info.message_url && task_info.notes
    task_properties['notes'] << task_info.notes if task_info.notes

    # Create the task. (Note: Until placed in a list, it is of little use.)
    task = @app.classesForScriptingNames['task'].alloc.initWithProperties(task_properties)

    
    # Create task in a list
    if task_info.list
      container_from_path(task_info.list).get.tasks.insertObject_atIndex(task,0) # (Adds at top of list. To instead add at bottom, use addObject(task) )
      # This assumes that container_from_path(task_info.list) always will return a list or a task
    else
      # No list specified, use inbox
      @app.inbox.tasks.insertObject_atIndex(task,0)  # (Adds at top of list. To instead add at bottom, use addObject(task) )
      NSLog "Created task '#{task.title}' in inbox."
    end

    # Set due date  
    set_due_date_for_task(task, Date.parse(task_info.due_date.to_s)) if task_info.due_date # When Date is
          # parsing like this, only the date (without time or time zone) will be left.
  end

  def set_due_date_for_task(task, date)
    id = id_for_task(task)

    # Workaround since I don't manage to get task.setDueDate to work correctly (it just sets the date to 1/1-1904)
    # Using applescript to set the date.
    sh = "osascript <<EOF
      tell application \"The Hit List\"
	    set due date of task id \"#{id}\" in inbox to date \"#{date}\"
      end tell
EOF
      "
    stdin, stdout, stderr = Open3.popen3(sh) # (Note: This can be picky about filenames, spaces etc.)
    stderr_txt = stderr.read.strip
    raise "Error from shell when creating task: #{stderr_txt}" if stderr_txt > ''

    return stdout.read.strip  # Returns the id of the new task.
  end

  def id_for_task(task)
     # Workaround to get id in the right form (not the numbers only form that task.id sometimes gives)
    return task.url.split('thehitlist://').last
  end

=begin
  def create_task(task_info, message)
    # Prepare the properties for the task
    task_properties = {}

    # Composing the title
      raise "Use 'title' instead of 'name'." if task_info.name # Warn for common misstake

      # If no name, fix default
      task_info.title = message.subject unless task_info.title

      # Set title
      task_properties['title'] = (task_info.title or 'Unnamed task')
        # Add contexts and tags
        task_properties['title'] +=   ' ' + task_info.tags if task_info.tags

    # relative due date - takes date from mail and adds a number of days to set a due date
      message.dateSent
      if task_info.relative_due_date

        task_properties['dueDate'] = xxx       # (Format: 2009-06-19 00:00:00 +0200)
      end


    # Create the future task (since it's not placed on a list yet, it's not a 'real' task yet.
    task = @app.classesForScriptingNames['task'].alloc.initWithProperties(task_properties)
    
    # Create task in a list
    if task_info.list
      container_from_path(task_info.list).get.tasks.insertObject_atIndex(task,0) # (Adds at top of list. To instead add at bottom, use addObject(task) )
      # This assumes that container_from_path(task_info.list) always will return a list or a task
    else
      # No list specified, use inbox
      @app.inbox.tasks.insertObject_atIndex(task,0)  # (Adds at top of list. To instead add at bottom, use addObject(task) )
    end





    # Set project
    #task.setAssignedContainer(project_from_path(task_info.project)) if task_info.project
    # Insert task into inbox
    #@app.inbox.tasks.insertObject_atIndex(task,0)  # (Adds at top of list. To instead add at bottom, use addObject(task) )



    # tell inbox to set theTask to make new task with properties {title:_title & " from " & _sender & " @email", notes:_messageURL}


  end
=end
  private

  def container_from_path(container_path)
    # Note: There is a mix of containers - folders, lists and super-tasks
    
    container_path = container_path.split('::')

    parent_container = @app.foldersGroup    # foldersGroup is the root for the folders etc.
    while container_path.size > 0 do
      # parent_container = parent_container.get   # TEST
      searching_for = container_path.shift.strip

      parent_container_class = parent_container.class   # TODO I'm not sure the get is needed. Check what is known without it.
      case parent_container_class.to_s

        when @app.classesForScriptingNames['folder'].class.to_s # Since the smart folders are sorted out, this is a folder (I think)
          matching_child_groups = parent_container.groups.select do |group|
            group.name == searching_for  # Note: This will
            # also match smart folders, so we need to filter those out. We do this in a separate pass
            # to avoid "get" to many times.
          end          
          matching_child_groups = matching_child_groups.reject do |group| 
            group.get.class.to_s == @app.classesForScriptingNames['smart folder'].class.to_s
          end

        when @app.classesForScriptingNames['list'].class.to_s, @app.classesForScriptingNames['task'].class.to_s
          matching_child_groups = parent_container.tasks.select{|task| searching_for = strip_tags_and_contexts(task.title) }

        else raise "Unknow class of parent container: '#{parent_container_class.to_s}"
      end
      # Check the result
      NSLog("WARNING. More than one group with name '#{searching_for}' in '#{parent_container.name}'. Using the first.") if matching_child_groups.size > 1 
            # TODO In lists, there can be several task with the same name. How handle that?
      raise "Can't find group '#{searching_for}' in '#{parent_container.name}'. " if matching_child_groups.size == 0
      parent_container = matching_child_groups.first  # (Should be only one). Used during the next loop or as result.
    end

    return @app.inbox if parent_container == @app.foldersGroup
    return parent_container
  end

  def strip_tags_and_contexts(title)
    # Returns all text before first /tag or @context
    return title.split(/ \//).first.split(/ @/).first.strip
  end

  def method_missing(method_name, *args)
    @app.send(method_name,*args)
  end
end


class Mail_app
  def initialize
    # Some code to remove the strange errors produced when using SBApplication.applicationWithBundleIdentifier
    # from http://www.dribin.org/dave/blog/archives/2008/05/27/sb_warnings/
    old_stderr = $stderr.clone        # save current STDERR IO instance
    $stderr.reopen('/dev/null', 'w')  # send STDERR to /dev/null
    @app = SBApplication.applicationWithBundleIdentifier('com.apple.Mail')
    $stderr.reopen(old_stderr)        # revert to default behavior
    old_stderr.close
  end

  def message_from_messageid(message_id, mailbox_path = "INBOX")
    mailbox = mailbox_from_mailbox_path(mailbox_path)
    for message in mailbox.messages.get
      return message if message.messageId == message_id
    end
    # Did not find the message. 
    NSLog "Did not find a message with messageId #{message_id} in mailbox '#{mailbox.name}'."
    raise "hell"
  end

  # Note: Har ingen s√§kerhet mot flera mailboxar med samma namn p√• samma niv√•. Men det kan man v√§l inte ha, eller???
  def mailbox_from_mailbox_path(mailbox_path)
    if mailbox_path == "INBOX"
      return @app.inbox
    else
      mailbox_steps = mailbox_path.split('/')
      context = @app
      for step in mailbox_steps
        for mailbox in context.mailboxes.get  # See Scripting Bridge Concepts, page 21, for more efficient looping
                # http://developer.apple.com/documentation/Cocoa/Conceptual/ScriptingBridgeConcepts/ScriptingBridgeConcepts.pdf
          if mailbox.name == step
            context = mailbox
            break   # Breaks *inner* loop
          end
        end
      end
      raise "Could not find mailbox '#{mailbox_path}." if context == @app
      return context
    end
  end

  def method_missing(method_name, *args)
    @app.send(method_name, *args)
  end

  def archive_selected_messages(into_mailbox)
    @app.selection.each {|message|  archive_mailmessage(message, into_mailbox)}
  end

  def archive_mailmessage(message, into_mailbox)
    # Check that it's actually a mail
    return false unless is_mailmessage?(message)

    # Archive it
    message.moveTo(mailbox_from_mailbox_path(into_mailbox))
    # message.moveTo(mailbox_from_path(into_mailbox))
  end

  private

  # Given a /-separated path (can be a single mailbox name) returns the mailbox object
  def mailbox_from_path(mailbox_path)    # I BELIVE THIS IS REPLACED BY mailbox_from_mailbox_path
    mailbox_path = mailbox_path.split('/')

    # The first mailbox in the path should have no parent
    top_mailbox_name = mailbox_path.shift
    #@app.mailboxes.each {|mailbox| puts mailbox.name}
    top_mailboxes = @app.mailboxes.select {|mailbox| mailbox.title == top_mailbox_name && mailbox.container.title == nil}
          # We need this since 'mailboxes' on the app gives a list of *all* mailboxes, regardless if they are
          # top or submailboxes. So if we only seclect by name, there is a risk that there exists more than one.
          # The root mailbox hovever has no name
    raise "More then one matching mailbox" if top_mailboxes.size > 1  # Assertion. This should never happen.
    raise "No top mailbox named #{top_mailbox_name}" if top_mailboxes.size == 0
    focus_mailbox = top_mailboxes[0]

    # Now that we have the starting point, the other levels of mailboxes are hierarchically ordered
    mailbox_path.each do |mailbox_name|
      mailboxes = focus_mailbox.mailboxes.select {|mailbox| mailbox.title == mailbox_name}
      raise "More then one matching mailbox" if mailboxes.size > 1  # Assertion. This should never happen.
      raise "No mailbox named #{mailbox_name} within #{focus_mailbox.title}" if mailboxes.size == 0
      focus_mailbox = mailboxes[0]
    end

    return focus_mailbox
  end

  def is_mailmessage?(msg)
    return msg.class.to_s == 'OSX::MailMessage'
  end
end

=begin
class OmniFocus_app
  def initialize
    # Some code to remove the strange errors produced when using SBApplication.applicationWithBundleIdentifier
    # from http://www.dribin.org/dave/blog/archives/2008/05/27/sb_warnings/
    old_stderr = $stderr.clone        # save current STDERR IO instance
    $stderr.reopen('/dev/null', 'w')  # send STDERR to /dev/null
    @app = SBApplication.applicationWithBundleIdentifier('com.omnigroup.OmniFocus')
    $stderr.reopen(old_stderr)        # revert to default behavior
    old_stderr.close
    
    @root = @app.documents.first
  end

  def method_missing(method_name, *args)
    @app.send(method_name,*args)
  end

  def create_task(task_info)
    # Seams the only (?) way to do this is to first create a task in the inbox, and then populate it
    # with name and other properties
    task = create_generic_task_in_inbox

    task.name = task_info.title if task_info.title    # If task_info.title is defined, it will replace the current name

    # Set context
    task.setContext(context_from_path(task_info.context)) if task_info.context

    # Set project
    task.setAssignedContainer(project_from_path(task_info.project)) if task_info.project
  end

  def create_generic_task_in_inbox()
    task_id = create_generic_task
    inbox_tasks =  @root.inboxTasks.get.to_a
    tasks = inbox_tasks.select do |task|
      inboxtask_id(task) == task_id
    end
    task = tasks.first
    return task
  end

=begin  
  def create_task_with_context_in_project(task_properties = {}, context_path = '', project_path = '')
    NSLog "task-properties: #{task_properties}"
    context = context_from_path(context_path)
    project = project_from_path(project_path)

    task = create_generic_task_in_inbox()   # (There should be only one)

    # Set properties
    if task_properties.has_key?('name')
      task.name = task_properties['name'] 
    end

    if task_properties.has_key?('dueDate')
      task.dueDate = task_properties['dueDate']
    end

    # Set context
    task.setContext(context) if context_path

    # Set project
    task.setAssignedContainer(project) if project_path

    # I can not find any way to 'clean up' or otherwise get the task to move out of the inbox and into 
    # the project.
  end
=end
=begin
  def create_generic_task # Creates a 'placeholder' task, that needs to get it's properties etc added later.
    # Seams to be a bug in using ScriptingBridge to create tasks. See http://forums.omnigroup.com/showthread.php?t=6875
    # and http://forums.omnigroup.com/showthread.php?p=43425#post43425 . As a workaround I'm using applescript.
    sh = "osascript <<END
      tell front document of application \"OmniFocus\"
	    set newTask to make new inbox task with properties {name:\"New Task\"}
	    get id of newTask
      end tell
END
      "
    stdin, stdout, stderr = Open3.popen3(sh) # (Note: This can be picky about filenames, spaces etc.)
    stderr_txt = stderr.read.strip
    raise "Error from shell when creating task: #{stderr_txt}" if stderr_txt > ''

    return stdout.read.strip  # Returns the id of the new task.
  end

  def inboxtask_id(inboxtask) # For some reason task.id will give a number (unlike for example in the browser of F-script)
    # so I'm extracting it instead
    taskid = /OmniFocusInboxTask id "(.*?)"/.match(inboxtask.to_s)[1]
    return taskid
  end

  def context_from_path(context_path)
    context_path = context_path.split(':')

    parent_context = @root
    while context_path.size > 0 do
      searching_for = context_path.shift
      contexts = parent_context.contexts.select{|context| context.title == searching_for }
      raise "More than one context with name #{searching_for}" if contexts.size > 1  # Assertion. Should never happen.
      raise "Can't find context '#{searching_for}'." if contexts.size == 0

      parent_context = contexts.first  # Used during next loop (if any)
    end

    return nil if parent_context == @root
    return parent_context
  end

  def project_from_path(project_path)
    project_path = project_path.split(':')

    parent = @root
    while project_path.size > 0 && parent.class.to_s != "OSX::OmniFocusProject" do  # (Projects has not the folders and projects methods)
      searching_for = project_path.shift

      folders = parent.folders.select{|folder| folder.title == searching_for }
      projects = parent.projects.select{|project| project.title == searching_for}
      folders_and_projects = folders + projects
      raise "More than one folder or project with name #{searching_for}" if folders_and_projects.size > 1  # Assertion. Should never happen.
      raise "Can't find a folder or project with name '#{searching_for}'." if folders_and_projects.size == 0

      parent = folders_and_projects.first # Used during next loop (if any)
    end

    return nil if parent == @root
    return parent  # Note, this can return a OSX::OmniFocusFolder - which can not be used for placing tasks in
  end
end
=end

=begin
module Mail_to_GTD
  @controller = Controller.new

  def task_template
    return @controller.task_template
  end
  
  def create_tasks_from_mail_messages_using_template(template)
    @controller.create_tasks_from_selected_messages(template)
  end

  module_function(:task_template, :create_tasks_from_mail_messages_using_template)
end
=end

# ==========================================================

# This code will only execute if this file is the file
# being run from the command line.
if $0 == __FILE__
  args = ARGV.first 

  controller = Controller.new
  message_id, mailbox, rule = args.split('#|#|#|#',3)
  NSLog "command line: Processing message '#{message_id}', in mailbox '#{mailbox}', using rule '#{rule}'."
  controller.process_message_rule(message_id, mailbox, rule)






=begin
  template = Mail_to_GTD::task_template

  template.title = "L‚Äö√†√∂¬¨√ümna tillbaka: "   # TODO: Make method that includes the titles of films/books here
  template.tags = "@biblioteket"
  template.list = "Todo"                        # TODO Familj::Familj funkar inte


  Mail_to_GTD::create_tasks_from_mail_messages_using_template(template)
=end

=begin
  controller = Controller.new
  template = controller.task_template


  # Info added to the template will effect all the tasks created from the selected messages.
  # (Though, normaly this is just one).
  template.name = "Satt i Automator"
  template.context = "P‚Äö√†√∂‚Äö√Ñ¬¢ stan:Ta med"
  template.project = "Datordrift:Datorsk‚Äö√†√∂‚Äö√†√átsel"


  controller.create_tasks_from_selected_messages(template)
=end
end