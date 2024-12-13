require "benchmark"

[
  "inputs/12_test1.txt",
  "inputs/12_test2.txt",
  "inputs/12_test3.txt",
  "inputs/12.txt",
].each do |filename|
  map, max_x, max_y = parse(filename)
  p1 = part1(map, max_x, max_y)
  puts "#{filename} part 1: #{p1}"
end

def parse(filename)
  map = File.read(filename).lines.map do |line|
    line.chars
  end
  {map, map[0].size - 1, map.size - 1}
end

class Region
  property key : Char
  property size : Int32 = 0
  property perimeter : Int32 = 0
  def initialize(@key)
  end
  def price
    @size * @perimeter
  end
end

def part1(map, max_x, max_y)
  visited = Array(Array(Bool)).new(max_y + 1) { Array(Bool).new(max_x + 1, false)}
  regions = Array(Region).new

  0.upto(max_y) do |y|
    0.upto(max_x) do |x|
      if !visited[y][x]
        new_region = Region.new(map[y][x])
        regions << new_region
        flood(map, map[y][x], x, y, max_x, max_y, visited, new_region)
      end
    end
  end

  regions.reduce(0) do |acc, region|
    acc + region.price
  end
end

def flood(map, char, x, y, max_x, max_y, visited, current_region)
  perimeters = x < 0 || x > max_x ? 1 : 0
  perimeters +=1 if y < 0 || y > max_y
  if perimeters > 0
    current_region.perimeter += perimeters
    return
  end
  if visited[y][x]
    current_region.perimeter += 1 if map[y][x] != char
    return
  end
  if map[y][x] != char
    current_region.perimeter += 1
    return
  end

  visited[y][x] = true
  current_region.size += 1
  flood(map, char, x+1, y, max_x, max_y, visited, current_region)
  flood(map, char, x-1, y, max_x, max_y, visited, current_region)
  flood(map, char, x, y+1, max_x, max_y, visited, current_region)
  flood(map, char, x, y-1, max_x, max_y, visited, current_region)
  return
end
