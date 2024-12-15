require "../2023/lib/vector2d"
alias Vec2 = Vector2d(Int32)

DRAW = true
DRAW_ALL_STEPS = false

[
  "inputs/15_test1.txt",
  "inputs/15_test2.txt",
  "inputs/15.txt",
].each do |filename|
  walls, boxes, robot_pos, moves = parse(filename)

  p1 = part1(walls, boxes, robot_pos, moves)
  puts "#{filename} part 1: #{p1}"

  if DRAW
    exit if STDIN.raw(&.read_char) == 'q'
    system("clear")
  end
end

def parse(filename)
  file = File.read(filename)
  walls = [] of Array(Bool)
  boxes = [] of Array(Bool)
  robot = Vec2.new(0, 0)
  map, moves = file.split("\n\n")
  map.lines.each_with_index do |line, y|
    walls << [] of Bool
    boxes << [] of Bool
    line.chars.each_with_index do |char, x|
      if char == '#'
        walls[y] << true
        boxes[y] << false
      elsif char == 'O'
        walls[y] << false
        boxes[y] << true
      elsif char == '@'
        robot = Vec2.new(x, y)
        walls[y] << false
        boxes[y] << false
      elsif char == '.'
        walls[y] << false
        boxes[y] << false
      else
        raise "unknown character: #{char} at line #{y}:#{x}"
      end
    end
  end

  move_offsets = moves.chars
  .select {|c| c == '<' || c == '^' || c == '>' || c == 'v'}
  .map do |c|
    case c
    when '<' then Vec2.new(-1, 0)
    when '^' then Vec2.new(0, -1)
    when '>' then Vec2.new(1, 0)
    when 'v' then Vec2.new(0, 1)
    else
      raise "oh no"
    end
  end

  {walls, boxes, robot, move_offsets}
end

def part1(walls, boxes, robot_pos, moves)
  system("clear") if DRAW
  moves.each do |direction|
    robot_pos = move(robot_pos, direction, walls, boxes)
    if DRAW && DRAW_ALL_STEPS
      draw(robot_pos, walls, boxes)
      # char = STDIN.raw &.read_char
      # break if char == 'q'
    end
  end
  if DRAW && !DRAW_ALL_STEPS
    draw(robot_pos, walls, boxes)
  end
  calculate_box_gps(boxes)
end

def move(robot_pos, direction, walls, boxes)
  new_position = robot_pos
  new_robot_pos = robot_pos + direction
  box_chain = new_position
  boxes_to_push = false
  iterations = 0

  loop do
    new_position = new_position + direction
    if DRAW && DRAW_ALL_STEPS
      debug_text = <<-EOF
        direction: #{direction}
        new_position: #{new_position}
        new_robot_pos: #{new_robot_pos}
        box_chain: #{box_chain}
        boxes_to_push: #{boxes_to_push}
        iterations: #{iterations}
      EOF
      print_at(0, boxes.size + 6, debug_text)
      print_at(2 + new_position.x * 2, 1 + new_position.y, "xx")
      sleep 0.033
    end

    iterations += 1 if DRAW
    if walls[new_position.y][new_position.x]
      # can't move robot or boxes in this direction
      print_at(2, boxes.size + 13, "hit a wall") if DRAW && DRAW_ALL_STEPS
      return robot_pos
    else
      print_at(2, boxes.size + 13, "          ") if DRAW && DRAW_ALL_STEPS
    end
    if boxes[new_position.y][new_position.x]
      boxes_to_push = true
      box_chain = new_position
      next
    else
      box_chain = new_position
      break
    end
  end

  if boxes_to_push
    print_at(2, boxes.size + 14, "found boxes to push") if DRAW && DRAW_ALL_STEPS
    boxes[new_robot_pos.y][new_robot_pos.x] = false
    boxes[box_chain.y][box_chain.x] = true
  end
  return new_robot_pos
end

def calculate_box_gps(boxes)
  sum = 0
  boxes.each_with_index do |row, y|
    row.each_with_index do |is_box, x|
      sum += (y * 100 + x) if is_box
    end
  end

  sum
end


def draw(robot_pos, walls, boxes)
  walls.each_with_index do |row, y|
    line = String.build do |str|
      row.each do |is_wall|
        str << (is_wall ? "██" : "  ")
      end
    end
    print_at(2, y+1, line)
  end
  boxes.each_with_index do |row, y|
    row.each_with_index do |is_box, x|
      next unless is_box
      print_at(2 + x*2, y + 1, "[]")
    end
  end
  print_at(2 + robot_pos.x*2, 1 + robot_pos.y, "@@")
  move_to(0, boxes.size + 3)
end

def print_at(x, y, contents)
  print "\e[#{y+1};#{x+1}H#{contents}"
end

def move_to(x, y)
  print "\e[#{y+1};#{x+1}H"
end
