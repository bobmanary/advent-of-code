
require_relative 'lib/intcode_computer'

class Grid
  attr_reader :grid

  def initialize
    @grid = {[0,0] => 0}
    @robot_pos = [0,0]
    @facings = [
      {facing: :left, offset: [-1,0]},
      {facing: :down, offset: [0, 1]},
      {facing: :right, offset: [1, 0]},
      {facing: :up, offset: [-1, 0]}
    ]
    @facings.each_with_index do |facing, i|
      facing[:left] = @facings[i+1]
      facing[:right] = @facings[i-1]
      if i == 3
        facing[:left] = @facings[0]
      end
      if i == 0
        facing[:right] = @facings[3]
      end

    end
    @facing = @facings[3]
  end

  def set(colour)
    @grid[@robot_pos] = colour
  end

  def get()
    if @grid[@robot_pos].nil?
      set(0)
    end
    @grid[@robot_pos]
  end

  def turn(dir)
    if dir == 0
      @facing = @facing[:left]
    else
      @facing = @facing[:right]
    end
    @robot_pos[0] += @facing[:offset][0]
    @robot_pos[1] += @facing[:offset][1]
  end

  def facing
    @facing[:facing]
  end
end

def run_program
  grid = Grid.new

  last_event = :paint # :paint
  comp = IntcodeComputer.new File.read('inputs/11.txt').split(',').map &:to_i
  # comp.add_inputs [0]
  while comp.run
    if comp.wait_output?
      if last_event == :movement
        grid.set(comp.consume_output)
        puts "paint #{grid.get}"
        last_event = :paint
      else
        output = comp.consume_output
        grid.turn(output)
        puts "#{grid.facing} #{output}"
        last_event = :movement
      end
    elsif comp.wait_input?
      comp.add_inputs [grid.get()]
    end
  end
  puts grid.grid
end

run_program