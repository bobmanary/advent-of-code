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

class Puzzle
  getter positions : Array(UInt16)
  def initialize(filename)
    @positions = File.read(filename).split(',').map(&.to_u16)
  end

  def run
    pos_max = @positions.max
    pos_min = @positions.min
    
    cheapest_fuel_cost = 4294967295_u32

    (pos_min..pos_max).each do |i|
      fuel_cost = @positions.reduce(0_u32) do |acc, pos|
        min = [i, pos].min
        max = [i, pos].max
        acc += (max - min)
      end
      cheapest_fuel_cost = fuel_cost if fuel_cost < cheapest_fuel_cost

      puts "position #{i}: #{fuel_cost} fuel"
    end

    cheapest_fuel_cost
  end
end


class Puzzle2
  getter positions : Array(UInt16)
  def initialize(filename)
    @positions = File.read(filename).split(',').map(&.to_u16)
  end

  def run
    pos_max = @positions.max
    pos_min = @positions.min
    
    cheapest_fuel_cost = 4294967295_u32

    (pos_min..pos_max).each do |i|
      total_fuel_cost = @positions.reduce(0_u32) do |acc, pos|
        min = [i, pos].min
        max = [i, pos].max
        distance = max - min
        crab_fuel_cost = 0
        distance.times do |j|
          crab_fuel_cost += j+1
        end

        acc += crab_fuel_cost
      end
      cheapest_fuel_cost = total_fuel_cost if total_fuel_cost < cheapest_fuel_cost

      puts "position #{i}: #{total_fuel_cost} fuel"
    end

    cheapest_fuel_cost
  end
end

puts Puzzle.new(filename).run
puts Puzzle2.new(filename).run
