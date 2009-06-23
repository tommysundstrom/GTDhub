require 'rubygems'
require 'osx/cocoa'
include OSX
OSX.require_framework 'ScriptingBridge'

class PerfomMailActionWithMessages_delegate < NSObject
  def perfomMailActionWithMessages_inMailboxes_forRule(messages, mailboxes, rule)
    NSLog "messages: " + messages.to_s
    NSLog "mailboxes: " + mailboxes.to_s
    NSLog "rule: " + rule.to_s
  end
end


if $0 == __FILE__
  mail = SBApplication.applicationWithBundleIdentifier('com.apple.Mail')
  delegate = PerfomMailActionWithMessages_delegate.alloc.init
  mail.setDelegate(delegate)
end