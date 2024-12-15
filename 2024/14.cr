[
  # {"inputs/14_test.txt", 11, 7},
  {"inputs/14.txt", 101, 103},
].each do |(filename, width, height)|
  paths = parse(filename)
  p1 = part1(paths, width, height)
  puts "#{filename} part 1: #{p1}"

  p2 = part2(paths, width, height)
  puts "#{filename} part 2: #{p2}"
end

def parse(filename)
  File.read(filename).lines.map do |line|
    matches = line.match!(/p=(\d+),(\d+) v=(-?\d+),(-?\d+)/)
    {matches[1].to_i, matches[2].to_i, matches[3].to_i, matches[4].to_i}
  end
  
end

def part1(paths, width, height)
  time_steps = 100
  #           [[TL, TR], [BL, BR]]
  quadrants = [[0,0],[0,0]]
  mid_x = width // 2
  mid_y = height // 2

  new_positions = calc_positions(paths, width, height, time_steps)
  new_positions.each do |(x, y)|
    q_left = x == mid_x ? -1 : x < mid_x ? 0 : 1
    q_top = y == mid_y ? -1 : y < mid_y ? 0 : 1
    next if q_top == -1 || q_left == -1
    quadrants[q_top][q_left] += 1
  end

  quadrants[0][0] * quadrants[0][1] * quadrants[1][0] * quadrants[1][1]
end

def calc_positions(paths, width, height, time_steps)
  #       (initial position, velocity)
  paths.map do |(x, y, vx, vy)|
    moved_x = vx * time_steps # how many positions right the robot moved
    pos_x = x + moved_x # absolute position if the robot didn't teleport
    looped_x = pos_x % width

    moved_y = vy * time_steps
    pos_y = y + moved_y
    looped_y = pos_y % height
    {looped_x, looped_y}
  end
end

def part2(paths, width, height)
  time_steps = 6644
  prev_positions = [] of {Int32, Int32}
  (height + 1).times { puts " " * width }
  loop do
    new_positions = calc_positions(paths, width, height, time_steps)
    draw_positions(new_positions, prev_positions, width, height, time_steps)
    prev_positions = new_positions
    time_steps += 1
  end
end

def draw_positions(positions, prev_positions, width, height, time)
  prev_positions.each do |(x, y)|
    print "\e[#{y+1};#{x*2+1}H  "
  end
  positions.each do |(x, y)|
    print "\e[#{y+1};#{x*2+1}H██"
  end
  print "\e[1;1Htime: #{time}\e[#{height+2};1H"
  char = STDIN.raw &.read_char
  exit 0 if char == 'q'
end

# p1 = 2,4
# v  = 2,-3
# w = 11
# h = 7
# t  = 5
# p2 = 1,3

# x1 + vx * t -  w * t = x2
# 2  +  2 * 5 - 11 * 5 = 1
# (  12     ) - 55     = 1
# (       -43        ) + 44 = 1         55 - 2 - 11
# 
# 