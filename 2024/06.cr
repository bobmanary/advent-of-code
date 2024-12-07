require "benchmark"
require "colorize"

["inputs/06_test.txt", "inputs/06.txt"].each do |filename|
  map, position = parse(filename)

  p1 = 0
  p2 = 0
  visited_hash = Hash({Int32, Int32}, Facing).new
  Benchmark.ips do |bm|
    bm.report do
      p1, visited_hash = part1(map, position.dup)
    end
    bm.report do
      p2 = part2(map, position, visited_hash)
    end
  end

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

@[Flags]
enum Facing
  Up
  Right
  Down
  Left
end

OFFSETS = {
  Facing::Up => {0, -1},
  Facing::Right => {1, 0},
  Facing::Down => {0, 1},
  Facing::Left => {-1, 0}
}

def parse(filename)
  lines = File.read(filename).lines
  map = Array(Array(Bool)).new(lines.size)
  width = lines[0].size
  position = {0,0}
  lines.each_with_index do |line, y|
    row = Array(Bool).new(width)
    line.chars.each_with_index do |char, x|
      position = {x, y} if char == '^'
      row << (char == '#')
    end
    map << row
  end

  {map, position}
end

def part1(map, position)
  max_y = map.size - 1
  max_x = map[0].size - 1
  facing = Facing::Up
  f_offset = OFFSETS[facing]
  visited_hash = Hash({Int32, Int32}, Facing).new

  loop do
    add_visit(visited_hash, position, facing)
    next_position = {position[0] + f_offset[0], position[1] + f_offset[1]}
    if next_position[0] < 0 || next_position[0] > max_y || next_position[1] < 0 || next_position[1] > max_x
      # exited map, we're done
      break
    end
    if map[next_position[1]][next_position[0]]
      # ran into an obstacle, turn right
      facing = next_facing(facing)
      f_offset = OFFSETS[facing]
      next
    end
    position = next_position
    # draw_map(map, position, facing, nil)
  end

  {visited_hash.size, visited_hash}
end

def part2(map, start_position, visited_hash)
  max_y = map.size - 1
  max_x = map[0].size - 1
  new_obstacles = Array({Int32, Int32}).new
  facing = Facing::Up
  f_offset = OFFSETS[facing]

  visited_hash.keys.each do |new_obstacle_pos|
    next if new_obstacle_pos == start_position

    facing = Facing::Up
    f_offset = OFFSETS[facing]
    map[new_obstacle_pos[1]][new_obstacle_pos[0]] = true
    loop_path = Set({ {Int32, Int32}, Facing}).new
    position = start_position
    loop do
      if loop_path.includes?({position, facing})
        new_obstacles << new_obstacle_pos
        break
      else
        loop_path << {position, facing}
      end

      next_position = {position[0] + f_offset[0], position[1] + f_offset[1]}
      if next_position[0] < 0 || next_position[0] > max_y || next_position[1] < 0 || next_position[1] > max_x
        # exited map, this permutation didn't loop
        break
      end
      if map[next_position[1]][next_position[0]]
        # ran into an obstacle, turn right
        facing = next_facing(facing)
        f_offset = OFFSETS[facing]
        next
      end
      position = next_position
    end
    map[new_obstacle_pos[1]][new_obstacle_pos[0]] = false
  end

  new_obstacles.size
end

def next_facing(facing)
  case facing
  when Facing::Up
    Facing::Right
  when Facing::Right
    Facing::Down
  when Facing::Down
    Facing::Left
  when Facing::Left
    Facing::Up
  else
    raise "Bad facing #{facing}"
  end
end

def draw_map(map, position, facing, potential_obstacle : {Int32, Int32}?)
  puts "\n\n"
  map.each_with_index do |row, y|
    row.each_with_index do |is_obstacle, x|
      if position == {x, y}
        char = case facing
        when Facing::Right
          '>'
        when Facing::Down
          'v'
        when Facing::Left
          '<'
        when Facing::Up
          '^'
        end
        print char.colorize(:red)
      elsif !potential_obstacle.nil? && potential_obstacle == {x, y}
        print 'O'
      else
        print is_obstacle ? '#' : '.'
      end
    end
    print '\n'
  end
end

def add_visit(visited_hash, position, facing : Facing)
  if visited_hash.has_key?(position) && !(vp = visited_hash[position]).nil?
    visited_hash[position] = facing | vp
  else
    visited_hash[position] = facing
  end
end
