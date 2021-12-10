
abstract class Window
  # this is basically each_cons but whatever
  include Iterator(Array(Int32))

  WINDOW_SIZE = 1

  @size : Int32
  @pos : Int32

  macro inherited
    def window_size
      WINDOW_SIZE
    end
  end

  def initialize(@ints : Array(Int32))
    @size = @ints.size
    @pos = 0
  end

  def next
    if (@pos + (window_size - 1)) < @size
      start_pos = @pos
      end_pos = @pos + window_size - 1
      @pos += 1
      @ints[start_pos..end_pos]
    else
      stop
    end
  end
end

class Window3 < Window
  WINDOW_SIZE = 3
end

class IncreaseCounter
  def initialize(@ints : Array(Int32)); end

  def run
    previous_depth = 2_147_483_647
    increase_count = 0
    @ints.each do |depth|
      if depth > previous_depth
        increase_count += 1
      end
      previous_depth = depth
    end

    increase_count
  end
end

inputs = File.read("inputs/01.txt").lines.map(&.to_i)
puts IncreaseCounter.new(inputs).run

puts IncreaseCounter.new(
  Window3.new(inputs).to_a.map(&.sum)
).run


puts (inputs.each_cons(3).to_a.each_cons(2).reduce(0) do |acc, (a, b)| b.sum > a.sum ? acc + 1 : acc end)
