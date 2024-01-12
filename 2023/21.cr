require "./lib/matrix"
require "./lib/asciimage"

class Vector
  property x, y : Int32
  def_hash @x, @y

  def initialize(@x : Int32, @y : Int32)
  end

  def +(other)
    Vector.new(
      @x + other.x,
      @y + other.y
    )
  end

  def add_if_bounded_by(bounding_corner : Vector, other : Vector) : Vector | Nil
    new_x = @x + other.x
    new_y = @y + other.y
    if new_x >= 0 && new_y >= 0 && new_x <= bounding_corner.x && new_y <= bounding_corner.y
      Vector.new(new_x, new_y)
    else
      nil
    end
  end

  def ==(other)
    @x == other.x && @y == other.y
  end

  def clone
    Vector.new(@x, @y)
  end
end

NORTH = Vector.new(0, -1)
EAST = Vector.new(1, 0)
SOUTH = Vector.new(0, 1)
WEST = Vector.new(-1, 0)

def parse(filename)
  lines = File.read(filename).lines
  width = lines.first.size
  height = lines.size
  start = Vector.new(-1, -1)

  array = Array(Char).new(width * height)
  lines.each_with_index do |line, y|
    array.concat line.chars
    start_pos = line.index('S')
    next if start_pos.nil?
    start = Vector.new(start_pos, y)
  end
  return Matrix(Char).new(array, width, height), start
end

def part1(map, start_position, steps_remaining)
  bounds = Vector.new(map.width - 1, map.height - 1)

  cache = Hash(Tuple(Vector, Int32), Set(Vector)).new

  reached_plots = walk(map, bounds, start_position, steps_remaining, Set(Vector).new, cache)
  reached_plots
end

def walk(map : Matrix(Char), bounds, position : Vector, steps_remaining : Int32, reached_plots : Set(Vector), cache)
  if steps_remaining == 0
    reached_plots << position
    return reached_plots
  end

  cache_key = {position, steps_remaining}
  if cache.has_key?(cache_key)
    # puts "#{steps_remaining}, #{position.x},#{position.y} has_key"
    return cache[cache_key]
  end

  # puts "#{steps_remaining}, #{position.x},#{position.y} no_key"


  directions = [NORTH, EAST, SOUTH, WEST].select do |direction|
    new_pos = position.add_if_bounded_by(bounds, direction)
    next if new_pos.nil? || map[new_pos.x, new_pos.y] == '#'
    reached_plots = reached_plots + walk(map, bounds, new_pos, steps_remaining - 1, reached_plots.clone, cache)
  end

  cache[cache_key] = reached_plots

  reached_plots
end

[{"inputs/21_example.txt", 6}, {"inputs/21.txt", 64}].each do |filename, steps|
  map, start_position = parse(filename)
  p1 = part1(map, start_position, steps)
  image = Asciimage.new(map)
  p1.each do |vector|
    image.plot(vector.x, vector.y, 'O')
  end
  image.render true
  puts "#{filename} part 1: #{p1.size}"
end
