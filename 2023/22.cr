require "./lib/matrix"
require "./lib/asciimage"

["inputs/22_example.txt", "inputs/22.txt"].each do |filename| #
  bricks, max_x, max_y, max_z = parse(filename)

  part1, part2 = calculate(bricks, max_x, max_y, max_z)
  puts "#{filename} part 1: #{part1}"
  puts "#{filename} part 2: #{part2}"
end

def parse(filename)
  max_x = 0
  max_y = 0
  max_z = 0
  id = 0
  bricks = File.read(filename).lines.map do |line|
    id += 1
    n = line.split(/[,~]/).map(&.to_i)
    max_x = max(max(n[0], n[3]), max_x)
    max_y = max(max(n[1], n[4]), max_y)
    max_z = max(max(n[2], n[5]), max_z)
    Brick.new(n[0], n[1], n[2], n[3], n[4], n[5], id)
  end
  {bricks.sort!, max_x, max_y, max_z}
end

def max(a, b)
  a > b ? a : b
end

def min(a, b)
  a < b ? a : b
end

def diff(a, b)
  a > b ? a - b : b - a
end

class Brick
  include Comparable(Brick)

  property id
  property x1, y1, z1, x2, y2, z2
  getter supported_bricks, supported_by

  def initialize(@x1 : Int32, @y1 : Int32, @z1 : Int32, @x2 : Int32, @y2 : Int32, @z2 : Int32, @id : Int32)
    # normalize coordinates so that x1/y1/z1 are smaller than x2/y2/z2 just in case?
    @x1, @x2 = @x2, @x1 if @x1 > @x2
    @y1, @y2 = @y2, @y1 if @y1 > @y2
    @z1, @z2 = @z2, @z1 if @z1 > @z2
    @supported_bricks = Set(Brick).new
    @supported_by = Set(Brick).new
  end

  def <=>(other)
    other_lowest = other.z1
    my_lowest = @z1
    if @z1 != other.z1
      @z1 <=> other.z1
    elsif @y1 != other.y1
      @y1 <=> other.y1
    else
      @x1 <=> other.x1
    end
  end

  def fall(field : Matrix3)
    new_z = @z1
    block_depth = @z2 - @z1

    while new_z > 1
      break if field.layer(new_z - 1).select_rect(@x1, @y1, @x2, @y2).any? {|b| !b.nil? }
      new_z -= 1
    end

    if new_z < @z1
      field.fill(@x1, @y1, @z1, @x2, @y2, @z2, nil)
      field.fill(@x1, @y1, new_z, @x2, @y2, new_z + block_depth, self)
      @z1 = new_z
      @z2 = new_z + block_depth
    end
  end

  def xy_coords : Array({Int32, Int32})
    if long_x?
      (@x1..@x2).map do |x|
        {x, @y1}
      end
    else
      (@y1..@y2).map do |y|
        {@x1, y}
      end
    end
  end
end

class Shuffler
  def initialize
    @array = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']
    @pos = 0
  end
  def next
    n = @array[@pos]
    @pos += 1
    @pos = 0 if @pos == @array.size
    n
  end
end


def calculate(bricks, max_x, max_y, max_z)
  field = Matrix3(Brick | Nil).new(max_x + 1, max_y + 1, max_z + 1, nil)
  shuffle = Shuffler.new

  img_offset1 = max_x + 4 # second column
  img_offset2 = max_y + img_offset1 + 4 # third column
  img_offset3 = max_x + img_offset2 + 4 # 4th
  img_width = img_offset3 + max_y + 1

  image = Asciimage.new(img_width, max_z + 1)
  image.fill(img_offset1 - 2, 0, img_offset1 - 2, max_z, '|')
  image.fill(img_offset2 - 2, 0, img_offset2 - 2, max_z, '|')
  image.fill(img_offset3 - 2, 0, img_offset3 - 2, max_z, '|')
  image.fill(0, 0, img_offset1 - 4, 0, '-')
  image.fill(img_offset1, 0, img_offset2 - 4, 0, '-')
  image.fill(img_offset2, 0, img_offset3 - 4, 0, '-')
  image.fill(img_offset3, 0, img_width - 1, 0, '-')
  

  bricks.each do |brick|
    field.fill(brick.x1, brick.y1, brick.z1, brick.x2, brick.y2, brick.z2, brick)
  end

  # drop each brick
  bricks.each do |brick|
    char = shuffle.next
    image.fill(brick.x1, brick.z1, brick.x2, brick.z2, char)
    image.fill(brick.y1 + img_offset1, brick.z1, brick.y2 + img_offset1, brick.z2, char)
    brick.fall(field)
    image.fill(brick.x1 + img_offset2, brick.z1, brick.x2 + img_offset2, brick.z2, char)
    image.fill(brick.y1 + img_offset3, brick.z1, brick.y2 + img_offset3, brick.z2, char)
  end

  image.render

  # part 1 + first pass to mapping supports
  # see which bricks are either
  # 1) not supporting other bricks, or
  # 2) not supporting any bricks with no other supports
  bricks.sort!
  disintegratable_bricks = Set(Brick).new
  bricks.each do |brick|
    brick_layer = field.layer(brick.z2)
    adjacent_bricks = (brick_layer.uniq - [brick]).reject(&.nil?)
    field.layer(brick.z2 + 1)
      .select_rect(brick.x1, brick.y1, brick.x2, brick.y2)
      .each do |maybe_brick|
        brick.supported_bricks << maybe_brick if !maybe_brick.nil?
      end

    if brick.supported_bricks.size == 0
      disintegratable_bricks << brick
      next
    end
    bricks_with_additional_supports = brick.supported_bricks.select do |sb|
      sb.supported_by << brick
      sb = sb.as(Brick)
      other_supports = brick_layer.select_rect(sb.x1, sb.y1, sb.x2, sb.y2).reject(&.nil?).uniq
      other_supports.size > 1
    end
    if bricks_with_additional_supports.size == brick.supported_bricks.size
      disintegratable_bricks << brick
    end
  end

  # part 2
  brick_chain_reaction_sum = 0
  bricks.each do |brick|
    previously_seen_ids = Set(Int32).new
    previously_seen_ids << brick.id
    falling_ids = Set(Int32).new
    supported_count = traverse_up(brick, previously_seen_ids, falling_ids)
    brick_chain_reaction_sum += falling_ids.size
  end

  return disintegratable_bricks.size, brick_chain_reaction_sum
end

def traverse_up(brick, previously_seen_ids, falling_ids)
  return if brick.supported_bricks.size == 0

  brick.supported_bricks.each do |upper_brick|
    fully_supported_by_falling_bricks = upper_brick.supported_by.all? do |lower_brick|
      falling_ids.includes?(lower_brick.id)
    end

    previously_seen_ids << upper_brick.id
    if upper_brick.supported_by.size == 1 || fully_supported_by_falling_bricks
      falling_ids << upper_brick.id
      traverse_up(upper_brick, previously_seen_ids, falling_ids)
    end
  end
end
