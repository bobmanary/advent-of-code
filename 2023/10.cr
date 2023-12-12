["inputs/10_example.txt", "inputs/10_example2.txt", "inputs/10.txt"].each do |filename|
  # "inputs/09.txt"
  input = File.read(filename).lines.map(&.chars)
  start = find_and_update_starting_point(input)
  # puts input.map(&.join).join("\n")

  puts "#{filename} part 1: #{part1(input, start)}"
  puts "#{filename} part 2: no thank you"
end

def part1(input, start)
  navigate(input, start) // 2
end

# these basic data classes were initially a failed experiment in using named tuples
class XyCoords
  property x, y
  def initialize(@x : Int32, @y : Int32)
  end

  def to_s(io : IO)
    io << "<Coords {x: #{@x}, y: #{@y}}>"
  end

  def ==(other : XyCoords)
    @x == other.x && @y == other.y
  end
end

class Dirs
  property top, right, bottom, left
  def each
    yield :top, @top
    yield :right, @right
    yield :bottom, @bottom
    yield :left, @left
  end

  def to_s(io : IO)
    io << "<Dir? {top: #{@top}, right: #{@right}, bottom: #{@bottom}, left: #{@left}}>"
  end

  def []=(direction : Symbol, state)
    case direction
    when :top then @top = state
    when :right then @right = state
    when :bottom then @bottom = state
    when :left then @left = state
    else
      raise "#{direction}? getouttahea"
    end
  end

  def [](direction : Symbol)
    case direction
    when :top then @top
    when :right then @right
    when :bottom then @bottom
    when :left then @left
    else
      raise "#{direction}? getouttahea"
    end
  end
end

class ValidDirChars < Dirs
  def initialize(@top : String, @right : String, @bottom : String, @left : String)
  end
end

class ValidDirs < Dirs
  def initialize(@top : Bool, @right : Bool, @bottom : Bool, @left : Bool)
  end

  def directions
    ds = [] of Symbol
    each do |dir, is_valid|
      ds << dir if is_valid
    end
    ds
  end
end

class ValidPositions < Dirs
  def initialize(@top : XyCoords, @right : XyCoords, @bottom : XyCoords, @left : XyCoords)
  end
end

DIRECTIONALITY = {
  '|' => {:top, :bottom},
  '-' => {:left, :right},
  'L' => {:top, :right},
  'J' => {:top, :left},
  '7' => {:left, :bottom},
  'F' => {:bottom, :right}
}
DIRECTION_MUTATIONS = {
  top: XyCoords.new(x: 0, y: -1),
  right: XyCoords.new(x: 1, y: 0),
  bottom: XyCoords.new(x: 0, y: 1),
  left: XyCoords.new(x: -1, y: 0)
}
FROM_DIR = {
  top: :bottom,
  right: :left,
  bottom: :top,
  left: :right
}

def navigate(input, start) : Int32
  cur_pos = XyCoords.new(x: start.x, y: start.y)
  cur_sym = input[start.y][start.x]
  next_dir = DIRECTIONALITY[cur_sym][0]
  from_dir = DIRECTIONALITY[cur_sym][1]
  steps = 0
  # puts "  #{steps} steps #{cur_pos} to #{next_dir} from #{from_dir}"
  
  while true
    break if cur_pos == start && steps > 0
    raise "too many steps" if steps > 140 * 140

    # this is wrong but it works???
    from_dir = FROM_DIR[next_dir]
    next_dir = get_next_dir(cur_sym, from_dir)
    
    mutate_coords(next_dir, cur_pos)
    cur_sym = input[cur_pos.y][cur_pos.x]
    steps += 1
    # puts "  #{steps} steps #{cur_sym} @ #{cur_pos} to #{next_dir} from #{from_dir}"
  end
  steps
end

def get_next_dir(cur_sym, from_dir)
  potential_dirs = DIRECTIONALITY[cur_sym]
  if potential_dirs[0] == from_dir
    potential_dirs[1]
  else
    potential_dirs[0]
  end
end

def get_sym_at(xy : XyCoords, input)
  input[xy.y][xy.x]
end

def mutate_coords(dir : Symbol, xy : XyCoords)
  offset = DIRECTION_MUTATIONS[dir]
  xy.x += offset.x
  xy.y += offset.y
  xy
end


def find_and_update_starting_point(input) : XyCoords
  # yikes
  start = nil
  x_max = input[0].size - 1
  y_max = input.size - 1

  input.each_with_index do |line, y|
    line.each_with_index do |char, x|
      if char == 'S'
        start = XyCoords.new(x: x, y: y)
      end
    end
  end
  raise "oh no" if start.nil?

  # figure out what shape the start pipe is, and update the map
  valid_dir_symbols = ValidDirChars.new(
    left: "-LF",
    right: "-J7",
    top: "|F7",
    bottom: "|LJ"
  )
  is_valid = ValidDirs.new(
    left: false,
    right: false,
    top: false,
    bottom: false
  )
  positions = ValidPositions.new(
    left:   XyCoords.new(x: start.x - 1, y: start.y),
    right:  XyCoords.new(x: start.x + 1, y: start.y),
    top:    XyCoords.new(x: start.x,     y: start.y - 1),
    bottom: XyCoords.new(x: start.x,     y: start.y + 1)
  )

  positions.each do |dir, coords|
    next if coords.x < 0 || coords.y < 0 || coords.x >= x_max || coords.y >= y_max
    # puts coords
    adjacent_char = input[coords.y][coords.x]
    valid_chars = valid_dir_symbols[dir]

    included = valid_chars.includes?(adjacent_char)
    # puts "#{adjacent_char} in #{dir} #{valid_chars}? #{included}"
    if included
      is_valid[dir] = true
    end
  end

  valid_dirs = is_valid.directions
  start_sym = '.'
  DIRECTIONALITY.each do |dir_sym, sym_dirs|
    if sym_dirs.includes?(valid_dirs[0]) && sym_dirs.includes?(valid_dirs[1])
      start_sym = dir_sym
      break
    end
  end

  input[start.y][start.x] = start_sym

  start
end

def pipe(char)
  
end
