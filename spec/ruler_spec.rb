require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ruler'

class Rules
  include Ruler
  def initialize
    #@DEBUG = true
  end
  
  def test_one
    ruleset do
    
      fact :firstone, true
      
      rule [:firstone] do
        true
      end

      default_rule do
        false
      end
    end
  end

  def test_two
    ruleset do
      fact :firstone, true
      
      rule [:firstone] do
        self.should_fire
        "this should be here"
      end
      
      rule [:firstone] do
        self.should_not_fire
        "this should not be here"
      end
    end

  end

  def test_three
    ruleset do

      fact :firstone, true
      fact :secondone, true
      fact :thirdone, false
      fact :fourthone, (1 == 1)
      fact :fifthone, (2 == 2)
      fact :sixthone, true

      rule [:firstone,:secondone,:thirdone, :fourthone, :fifthone] do
        false
      end
      
      rule [:firstone,:secondone,:sixthone, :fourthone, :fifthone] do
        true
      end
    end
  end

  def test_four
    ruleset do
      fact :firstone do
        true || true || false
      end
      fact :secondone, true
      fact :thirdone, true
      
      rule [:firstone, :secondone, :thirdone] do
        true
      end
    end
  end

  def test_five
    ruleset do
      fact :firstone, false

      rule [:firstone] do
        false
      end
      
      default_rule do
        true
      end
    end
  end

  def test_six
    ruleset do
      fact :firstone, false
      fact :secondone, notf(:firstone)
      
      rule [:secondone] do
        true
      end
    end
  end

  def test_seven
    multi_ruleset do
      fact :firstone, true
      fact :secondone, true
      
      rule [:firstone] do
        self.test_seven_multi
        true
      end

      rule [:secondone] do
        self.test_seven_multi
        true
      end
    end
  end

  def test_eight
    ruleset do
      fact :firstone, true

      rule [:firstone],"""
This is the documentation for this rule.
It can be on multiple lines if you 
do it right. This is a ruby limitation,
I think.
""" do 
        true
      end
    end
  end

  def test_nine
    multi_ruleset do
      default_rule do
        true
      end
    end
  end

  def test_ten 
    #@DEBUG = true
    ruleset do
      dynamic_fact :one do
        self.checking_method
      end
      
      fact :wrong, false

      rule [:one, :wrong] do
        false
      end

      rule [:one, :one, :wrong] do
        false
      end
    end
  end

  def test_eleven
    ruleset do
      dynamic_fact :one do 
        true
      end
      
      fact :two, notf(:one)
      
      default_rule do
        true
      end
    end
  end
end

describe Rules do
  it "should process a simple rule" do
    r = Rules.new
    r.test_one.should be(true)
  end

  it "should only process the first matching rule" do
    r = Rules.new
    r.expects(:should_fire)
    r.test_two.should == "this should be here"
  end

  it "should process rules with several conditions" do
    r = Rules.new
    r.test_three.should be(true)
  end

  it "should handle ORs" do
    r = Rules.new
    r.test_four.should be(true)
  end

  it "should respect the default rule" do
    r = Rules.new
    r.test_five.should be(true)
  end

  it "should run correctly with notf" do
    r = Rules.new
    r.test_six.should be(true)
  end

  it "should run multi_rulesets" do
    r = Rules.new
    r.expects(:test_seven_multi).twice
    r.test_seven.should be(true)
  end

  it "should run even with docstrings" do
    r = Rules.new
    r.test_eight.should be(true)
  end

  it "should throw if there is a defualt rule in a multimatch" do
    r = Rules.new
    lambda { r.test_nine.should}.should raise_error
  end

  it "should call dynamic rules each time they are evaluated" do
    r = Rules.new
    r.expects(:checking_method).times(3).returns(true)
    r.test_ten.should be(nil)
  end

  it "should throw an exception if a dyanmic fact is declared in a notf" do
    r = Rules.new
    lambda { r.test_eleven }.should raise_error
  end

end

