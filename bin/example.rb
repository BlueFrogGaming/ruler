
require 'rubygems'
require 'lib/ruler'

class TeaDrinker
  include Ruler
  attr_accessor :tea

  def initialize
    @DEBUG = true
  end

  def make_iced_tea
      puts "Making tea"
    end

  def drink_iced_tea
      puts "Ahhhhhhh"
    end

  def thirsty?
      true
    end

  def tea_check outside_temp
      ruleset do
         fact :it_is_hot  do outside_temp >= 100.0 end
         fact :iced_tea_made, true
         fact :no_iced_tea, notf(:iced_tea_made)
         fact :am_thirsty, self.thirsty?

         rule [:it_is_hot, :am_thirsty, :no_iced_tea] do
        make_iced_tea
           end

         rule [:it_is_hot, :am_thirsty, :iced_tea_made] do
        drink_iced_tea
           end
          end
    end
  end

t = TeaDrinker.new
puts t.tea_check 190.0
