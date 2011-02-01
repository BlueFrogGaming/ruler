# This module provides a set of methods to manage and run sets of facts and rules.
# These rules take an array of fact names and all of the facts are true
# the block passed to the rule is executed.  By default, only one rule can fire in a given ruleset.
# Each ruleset can have a default_rule which is executed if no rule fires (and the ruleset only allows
# one rule to fire)

# Author::    Josh Smith (josh@bluefroggaming.com)
# Copyright:: (c) 2011 Blue Frog Gaming, All Rights Reserved
# License:: This file has no public license.  

class RulerError < StandardError
end

class BadDefaultRule < RulerError
end

class BadNotCall < RulerError
end

module Ruler
# This module uses thread local storage and should be threadsafe. 
#
# A ruleset is the method that wraps all calls to fact and rule.
# A ruleset takes two arguments, the first is a boolean that determins if
# more than one rule can fire.  If this value is true, that ruleset allows only one
# rule to fire (this is the default). If this value is false,  all rules that evaluate to
# true will fire.  rulesets can also include a default_rule, which behaves as a normal rule
# that is always true.  The default_rule obeys the ruleset's singletary status
# A short example:
#
#      result = ruleset do
#            fact :is_true, true
#            fact :water_is_wet, true
#            fact :cannot_push_on_a_rope, true
#  
#            fact :do_not_mess_with_jim do
#               false
#            end
#            fact :pi_greater_than_four do
#               Math::PI > 4
#             end
#
#           rule [:is_true, :water_is_wet, :do_not_mess_with_jim] do
#             rand()
#           end
#           
#           rule [:cannot_push_on_a_rope, :water_is_wet, :is_true] do
#              42
#           end
#           
#           default_rule do
#              100
#           end
#         end
# puts result

  def ruleset singletary = true,&blk
    Thread.current[:singletary] = singletary
    Thread.current[:rulematched] = nil
    Thread.current[:working_memory] = {}
    yield
  end

# multi_ruleset is a helper function to define rulesets that allow
# more than one rule to fire  
  def multi_ruleset &blk
    ruleset false,&blk
  end

# a fact takes a symbol name and either a value or a block. 
# for example:
#     fact :factname, true
#     fact :otherfactname do
#               some_computation_that_evaluates_to_true_or_false
#     end
# 
# Facts may be defined anywhere in the ruleset. due to the 
# evaluation order, facts that appear after the last rule 
# will never be used.
  def fact name, dval = nil, &blk
    if dval.nil?
      Thread.current[:working_memory][name] = {:value => yield }
    else
      Thread.current[:working_memory][name] = {:value => dval }
    end
  end

# a dynamic_fact is evaulated every time the fact is checked.  Unlike a normal fact, which 
# is only evaluated once, dynamic facts are evaluated once for each rule they appear in
  def dynamic_fact name, &blk
    Thread.current[:working_memory][name] = {:transient => true, :block => blk }
  end

# allows for a fact to be NOT another fact.  notf cannot be used with a dynamic_fact
# for example:
#     fact :one, 10 == 10
#     fact :notfone, not(:one)
  def notf name
    if Thread.current[:working_memory][name][:transient]
      raise BadNotCall.new("Cannot call notf on dynamic fact")
    else
      not(Thread.current[:working_memory][name][:value])
    end
  end

# a rule takes a list of fact names and a block.  Rules are evaluated in the order
# they appear in the ruleset and are evaluated at execution time.  If all of the facts are true, then
# that rule is fired. If the ruleset is singletary, only one rule (the first rule to be true)
# may fire.  
# rules may also have docstrings.  These aren't really used yet,
# but they will be and they provide a nice alternative to commenting.
# For example:
#      rule [:one_fact, :two_facts], "this is the docstring" do
#          some_method
#      end
# there is no check to see if fact names are valid,  and facts can be (re)defined
#inside of rules.  Fact names are false if they are not defined.
  def rule vlist,docstr = nil,&blk
    dbg = lambda {|va|  puts Thread.current[:working_memory][va][:transient].nil? ? "|=-\t#{va} = #{Thread.current[:working_memory][va][:value]}" : "|=-\t#{va} = #{Thread.current[:working_memory][va][:block].call()}" }
    if @DEBUG
      puts "---------------------------------------"
      puts vlist.join(" & ")
      puts "======================================="
      vlist.each {|v| dbg.call(v) }
      puts "---------------------------------------"
    end
    if Thread.current[:singletary] && Thread.current[:rulematched]
      Thread.current[:rulematched]
    else
      conditional_call = lambda {|n| Thread.current[:working_memory][n][:transient].nil? ? Thread.current[:working_memory][n][:value] : Thread.current[:working_memory][n][:block].call() }
      Thread.current[:rulematched] = if vlist.inject(true) {|k,v| k ? k && conditional_call.call(v) : false }
                                       yield 
                                     end
    end
  end

# the default_rule is simple a rule that is always true.  This is mostly syntactic-sugar to represent
# a rule that should fire if no others fire. You cannot have a default rule if you allow more
# than one match.  The BadDefaultRule exception is raised.
  def default_rule &blk
    raise BadDefaultRule.new("Can't have a default rule when multiple matches are allowed") unless Thread.current[:singletary]
    if Thread.current[:singletary] && !Thread.current[:rulematched]
      yield
    else
      Thread.current[:rulematched]
    end
  end
end
