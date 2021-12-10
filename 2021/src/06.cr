require "option_parser"

class Pool
  getter fish : Array(Fish)
  def initialize
    @fish = [] of Fish
  end

  def add(new_fish : Fish)
    @fish << new_fish
  end

  def age_all_fish
    @fish[0..].each(&.age)
    # puts @fish.map { |f| f.timer }.join(',')
  end

  def run(iterations : Int32)
    # puts @fish.map { |f| f.timer }.join(',')
    iterations.times do age_all_fish end
  end

  def load(filename)
    File.read(filename).split(',').map(&.to_u8).each do |age|
      @fish << Fish.new(age, self)
    end
    self
  end
end

class Fish
  getter timer : UInt8
  def initialize(@timer, @pool : Pool, @quantity = 0)
  end

  def age
    if @timer == 0
      @timer = 6
      spawn_fish
    else
      @timer -= 1
    end
  end

  def spawn_fish
    @pool.add(Fish.new(8_u8, @pool))
  end
end

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

pool = Pool.new.load(filename)
pool.run(iterations)
puts "count after #{iterations} iterations: #{pool.fish.size}"
