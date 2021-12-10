
class GridLoadError < Exception
end

class Grid
  getter width
  getter height
  getter grid : Array(Array(Int32))
  def initialize(@width : Int32)
    @height = @width
    @grid = @width.times.map do
      @height.times.map do
        0
      end.to_a
    end.to_a
  end

  def import(lines)
    lines.each do |line|
      begin
        match = line.match(/(\d+),(\d+) -> (\d+),(\d+)/)
        if match
          x1, y1, x2, y2 = match[1..4]
          add_line(x1.to_i, y1.to_i, x2.to_i, y2.to_i)
        else
          raise GridLoadError.new(line)
        end
      rescue error : IndexError
        puts error
        puts error.backtrace
        
        puts line
        exit 1
      end      
    end
    self
  end

  def add_line(x1, y1, x2, y2)
    if x1 == x2
      range(y1, y2).each do |i|
        @grid[i][x1] += 1
      end
      return true
    end

    if y1 == y2
      range(x1, x2).each do |i|
        @grid[y1][i] += 1
      end
      return true
    end

    false
  end

  def to_s(io)
    padding = @height.to_s.size + 1
    io << " " * padding
    
    @width.times do |i| io << i << " " end
    io << "\n\n"

    @grid.each_with_index do |line, i|
      io << i.to_s.ljust(padding)
      line.each do |count|
        if count.zero?
          io << ". "
        else
          io << count << " "
        end
      end
      io << "\n"
    end

    io
  end

  def range(start, finish)
    if start > finish
      finish..start
    else
      start..finish
    end
  end

  def overlaps
    @grid.reduce(0) do |acc, line|
      acc + line.count {|pos| pos > 1}
    end
  end
end

class GridWithDiagonals < Grid
  def add_line(x1, y1, x2, y2)
    return if super

    # rx, ry = range_diagonal(x1, y1, x2, y2)
    # puts "#{rx} #{ry}"
    # ry_a = ry.to_a
    # rx.each_with_index do |x, i|
    #   y = ry_a[i]
    #   puts "#{x},#{y}"
    #   @grid[x][y] += 1
    # end
    # true

    DiagonalRange.new(x1, y1, x2, y2).each do |x, y|
      @grid[y][x] += 1
    end

    true
  end

  def range_diagonal(x1, y1, x2, y2)
    start_x = x1 > x2 ? x2 : x1
    start_y = y1 > y2 ? y2 : y1
    end_x = x2 > x1 ? x2 : x1
    end_y = y2 > y1 ? y2 : y1

    {(start_x..end_x), (start_y..end_y)}
  end
end

class DiagonalRange
  def initialize(@x1 : Int32, @y1 : Int32, @x2 : Int32, @y2 : Int32)
  end

  def each
    x_increment = @x1 > @x2 ? -1 : 1
    x_current = @x1
    x_steps = @x1 > @x2 ? @x1 - @x2 : @x2 - @x1

    y_increment = @y1 > @y2 ? -1 : 1
    y_current = @y1

    while x_steps >= 0
      yield x_current, y_current
      x_current += x_increment
      y_current += y_increment
      x_steps -= 1
    end
  end
end

grid = Grid.new(10).import(File.read("inputs/05_test.txt").lines)
puts grid
puts "part 1 test overlaps: #{grid.overlaps}"

input = File.read("inputs/05.txt").lines
max_coordinate = input.map {|r| r.split(/[^\d]+/).map(&.to_i)}.flatten.max
grid2 = Grid.new(max_coordinate + 1).import(input)
# puts grid2
puts "part 1 overlaps: #{grid2.overlaps}\n\n"

grid3 = GridWithDiagonals.new(10).import(File.read("inputs/05_test.txt").lines)
puts grid3
puts "part 2 test overlaps: #{grid3.overlaps}"

grid4 = GridWithDiagonals.new(max_coordinate + 1).import(input)
# puts grid4
puts "part 2 overlaps: #{grid4.overlaps}"
