require "option_parser"

filename = ""
iterations = 1
OptionParser.parse do |parser|
  parser.on "-f NAME", "--file", "Filename" do |name|
    filename = name
  end

  parser.on "-i ITERATIONS", "--iterations", "Iterations" do |i|
    iterations = i.to_i
  end
end

class FastPool
  getter groups
  def initialize
    @groups = [] of FastFishGroup
  end

  def load(filename)
    File.read(filename).split(',').map(&.to_u8).each do |age|
      group = @groups.find {|g| g.timer == age}
      if group.nil?
        group = FastFishGroup.new(age, 0_u128)
        @groups << group
      end
      group.quantity += 1
    end

    self
  end

  def run(iterations : Int32)
    iterations.times do |i|
      temp_groups = @groups.sort_by { |g| g.timer }.reverse
      @groups.clear

      temp_groups.each do |group|
        if group.timer == 0
          group6 = find_or_create_by_age(6_u8)
          group6.quantity += group.quantity
          @groups << FastFishGroup.new(8_u8, group.quantity)
        else
          same_timer_group = find_or_create_by_age group.timer - 1
          if same_timer_group
            same_timer_group.quantity += group.quantity
          else
            @groups << FastFishGroup.new(group.timer - 1, group.quantity)
          end
        end
      end
    end
  end

  def find_or_create_by_age(age)
    same_timer_group = @groups.find { |g| g.timer == age }
    if !same_timer_group
      same_timer_group = FastFishGroup.new(age, 0_u128)
      @groups << same_timer_group
    end

    same_timer_group
  end

  def size
    @groups.reduce(0_u128) {|acc, fg| acc + fg.quantity}
  end
end

class FastFishGroup
  property timer : UInt8
  property quantity : UInt128
  def initialize(@timer, @quantity); end
end

pool = FastPool.new.load(filename)
pool.run(iterations)
puts "count after #{iterations} iterations: #{pool.size}"
