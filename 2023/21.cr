require "./lib/matrix"
require "./lib/asciimage"
require "./lib/vector2d"
NORTH = Vector2d(Int32).new(0, -1)
EAST = Vector2d(Int32).new(1, 0)
SOUTH = Vector2d(Int32).new(0, 1)
WEST = Vector2d(Int32).new(-1, 0)

def parse(filename)
  lines = File.read(filename).lines
  width = lines.first.size
  height = lines.size
  start = Vector2d(Int32).new(-1, -1)

  array = Array(Char).new(width * height)
  lines.each_with_index do |line, y|
    array.concat line.chars
    start_pos = line.index('S')
    next if start_pos.nil?
    start = Vector2d(Int32).new(start_pos, y)
  end
  return Matrix(Char).new(array, width, height), start
end

def part1(map, start_position, steps_remaining)
  bounds = Vector2d(Int32).new(map.width - 1, map.height - 1)

  cache = Hash(Tuple(Vector2d(Int32), Int32), Set(Vector2d(Int32))).new

  reached_plots = walk(map, bounds, start_position, steps_remaining, Set(Vector2d(Int32)).new, cache)
  reached_plots
end

def walk(map : Matrix(Char), bounds, position : Vector2d(Int32), steps_remaining : Int32, reached_plots : Set(Vector2d(Int32)), cache)
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
