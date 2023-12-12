["inputs/11_example.txt", "inputs/11.txt"].each do |filename|
  image = SpaceImage.parse(File.read(filename), 2)
  SpaceImageRenderer.render(image)
  puts "#{filename} part 1: #{image.calculate_path_sum}"

  image2 = SpaceImage.parse(File.read(filename), 1_000_000)
  puts "#{filename} part 2: #{image2.calculate_path_sum}"
end

class Point
  property x, y, index
  def initialize(@x : Int32, @y : Int32, @index : Int32)
  end
end

class SpaceImage
  getter points, width, height

  def initialize(@width : Int32, @height : Int32)
    @points = [] of Point
  end

  def self.parse(input, expansion_factor)
    lines = input.lines
    initial_width = lines[0].size
    initial_height = lines.size
    image = SpaceImage.new(initial_width, initial_height)

    # while iterating over chars, figure out whether a column/row has a gap
    x_gaps_b = Array(Bool).new(initial_width, true)
    y_gaps_b = Array(Bool).new(initial_height, true)

    galaxies = 0
    lines.each_with_index do |line, y|
      line.chars.each_with_index do |char, x|
        if char == '#'
          galaxies += 1
          x_gaps_b[x] = false
          y_gaps_b[y] = false
          image.points << Point.new(x, y, galaxies)
        end
      end
    end

    x_gaps = gap_bitmap_to_cumulative(x_gaps_b, expansion_factor - 1)
    y_gaps = gap_bitmap_to_cumulative(y_gaps_b, expansion_factor - 1)

    image.expand(x_gaps, y_gaps)
    image
  end

  def self.gap_bitmap_to_cumulative(bitmap, expansion) : Array(Int32)
    cumulative = [] of Int32
    lead = false
    bitmap.each_with_index.reduce(0) do |acc, (is_gap, i)|
      acc += is_gap ? expansion : 0
      cumulative << acc
      acc
    end
    cumulative
  end

  def expand(x_gaps, y_gaps)
    @width += x_gaps.last
    @height += y_gaps.last

    @points.each do |point|
      point.x += x_gaps[point.x]
      point.y += y_gaps[point.y]
    end
  end

  def calculate_path_sum
    @points.each_with_index.reduce(0u64) do |sum, (point, i)|
      @points[i+1..].each_with_index(i+1) do |other, j|
        sum += distance(point.x, other.x) + distance(point.y, other.y)
      end
      sum
    end
  end
end

def distance(a, b)
  if a > b
    a - b
  else
    b - a
  end
end

class SpaceImageRenderer
  def self.render(image)
    puts "#{image.width}x#{image.height}"
    print "  "
    image.width.times do |x|
      print x.to_s.chars.last
    end
    puts ""
    image.height.times do |y|
      print "#{y.to_s.chars.last} "
      image.width.times do |x|
        if galaxy = image.points.find {|g| g.x == x && g.y == y}
          print galaxy.index.to_s.chars.last
        else
          print '.'
        end
      end
      puts ""
    end
  end
end
