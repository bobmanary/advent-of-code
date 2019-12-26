# if asteroid is at 20,8, potential blocking asteroids could be at
# 5,2
# 10,4
# 15,6

# require 'prime'
DEBUG=!ENV['DEBUG'].nil?
require 'set'

class Point
  attr_reader :x, :y
  def self.create(is_asteroid, x, y)
    if is_asteroid
      Asteroid.new(x, y)
    else
      EmptySpace.new(x, y)
    end
  end

  def initialize(x, y)
    @x = x
    @y = y
  end
end

class EmptySpace < Point
  def asteroid?
    false
  end
end

class Asteroid < Point
  attr_accessor :count
  def initialize(*args)
    super(*args)
    @count = 0
  end
  def asteroid?
    true
  end

  def each_other_cell(grid)
    grid.flatten.filter(&:asteroid?).each do |asteroid|
      next if asteroid == self
      yield
    end
  end
end

def get_potential_intersections(x, y)
  x_fix = x < 0 ? -1 : 1
  y_fix = y < 0 ? -1 : 1
  if x == 0
    return (1..y.abs-1).map do |yy|
      [0, yy * y_fix]
    end
  elsif y == 0
    return (1..x.abs-1).map do |xx|
      [xx * x_fix, 0]
    end
  end

  result = x.abs*y.abs

  x_divisors = (0..result).step(x.abs).map(&:to_i).to_set
  y_divisors = (0..result).step(y.abs).map(&:to_i).to_set
  intersections = x_divisors.intersection(y_divisors)

  points = intersections.map do |n|
    [n/y.abs, n/x.abs]
  end.reject do |point|
    point == [0,0] || point == [x.abs,y.abs]
  end.map do |(x, y)|
    [x*x_fix, y*y_fix]
  end
end

def get_relative_offset(point1, point2)
  rx = point2.x - point1.x
  ry = point2.y - point1.y
  [rx, ry]
end

def parse_map(map)
  lines = map.chomp.lines.map(&:chomp)
  width = lines[0].size
  height = lines.size

  grid = lines.map.with_index do |line, y|
    line.split('').map.with_index do |char, x|
      Point.create(char == '#', x, y)
    end
  end
  pp grid  if DEBUG
  {
    width: width,
    height: height,
    grid: grid
  }
end

def update_asteroid_los_counts!(grid)
  debug_point = grid[0][1]
  puts "debug point: #{debug_point.x},#{debug_point.y}" if DEBUG

  each_asteroid(grid) do |point1, x1, y1|
    each_asteroid(grid) do |point2, x2, y2|
      next if point1 == point2

      offset_x, offset_y = get_relative_offset(point1, point2)
      potential_intersections = get_potential_intersections(offset_x, offset_y)
      actual_intersections = potential_intersections.select do |(int_x, int_y)|
        pp [offset_x, offset_y, int_x, int_y, x1 + offset_x, y1 + offset_y] if DEBUG

        grid[y1 + int_y][x1 + int_x].asteroid?
      end

      if point1 == debug_point && DEBUG
        puts "checking against #{point2.x},#{point2.y} (#{x2},#{y2}) (potential: #{potential_intersections.size}, actual: #{actual_intersections.size})"
        # if actual_intersections > 0
        pp potential_intersections
        pp actual_intersections
      end

      if actual_intersections.size == 0
        if point1 == debug_point
          puts "  found clear los" if DEBUG
        end
        point1.count += 1
      end

    end
  end

  drawing = grid.map do |row|
    row.map do |point|
      point.asteroid? ? point.count.to_s : '.'
    end.join('')
  end.join("\n")
  puts drawing
end

def find_best_asteroid(grid)
  best = nil
  each_asteroid(grid) do |point|
    if best.nil? || best.count < point.count
      best = point
    end
  end
  best
end

def each_asteroid(grid)
  grid.each_with_index do |row, y|
    row.each_with_index do |point, x|
      next if !point.asteroid?
      yield(point, x, y)
    end
  end
end

if ARGV[0] == '--test'
  test_cases = [
    {
      expect: 8,
      map: <<~MAP
      .#..#
      .....
      #####
      ....#
      ...##
      MAP
    },
    {
      expect: 33,
      map: <<~MAP
      ......#.#.
      #..#.#....
      ..#######.
      .#.#.###..
      .#..#.....
      ..#....#.#
      #..#....#.
      .##.#..###
      ##...#..#.
      .#....####
      MAP
    },
    {
      expect: 35,
      map: <<~MAP
      #.#...#.#.
      .###....#.
      .#....#...
      ##.#.#.#.#
      ....#.#.#.
      .##..###.#
      ..#...##..
      ..##....##
      ......#...
      .####.###.
      MAP
    },
    {
      expect: 41,
      map: <<~MAP
      .#..#..###
      ####.###.#
      ....###.#.
      ..###.##.#
      ##.##.#.#.
      ....###..#
      ..#.#..#.#
      #..#.#.###
      .##...##.#
      .....#.#..
      MAP
    },
    {
      expect: 210,
      map: <<~MAP
      .#..##.###...#######
      ##.############..##.
      .#.######.########.#
      .###.#######.####.#.
      #####.##.#.##.###.##
      ..#####..#.#########
      ####################
      #.####....###.#.#.##
      ##.#################
      #####.##.###..####..
      ..######..##.#######
      ####.##.####...##..#
      .#####..#.######.###
      ##...#.##########...
      #.##########.#######
      .####.#.###.###.#.##
      ....##.##.###..#####
      .#.#.###########.###
      #.#.#.#####.####.###
      ###.##.####.##.#..##
      MAP
    }
  ]

  test_cases.each do |test_case|
    map = parse_map(test_case[:map])
    update_asteroid_los_counts!(map[:grid])
    best = find_best_asteroid(map[:grid])
    puts "best is #{best.x},#{best.y} with #{best.count} (#{best.count == test_case[:expect] ? 'PASS' : 'FAIL'})"
    puts "---"
  end
else
  map = parse_map(File.read('inputs/10.txt'))
  update_asteroid_los_counts!(map[:grid])
  best = find_best_asteroid(map[:grid])
  puts "best is #{best.x},#{best.y} with #{best.count}"
end
