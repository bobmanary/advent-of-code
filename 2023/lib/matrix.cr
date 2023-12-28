class Matrix(T)
  getter array : Array(T)
  getter width, height

  delegate :any?, :uniq, to: @array

  def initialize(@width : Int32, @height : Int32, default_value : T? = nil)
    @max_size = @width * @height
    if default_value
      @array = Array(T).new(@max_size, default_value)
    else
      @array = Array(T).new(@max_size)
    end
  end

  def initialize(@array : Array(T), @width : Int32, @height : Int32)
    @max_size = @width * @height
  end

  def [](x : Int32, y : Int32) : T
    offset = @width * y + x
    # puts "#{offset}/#{@max_size}/#{@array.size}"
    @array[offset]
  end

  def []=(x : Int32, y : Int32, item : T) : T
    offset = @width * y + x
    @array[offset] = item
  end

  def <<(item : T)
    if @array.size == @max_size
      raise "Too many items!"
    end
    @array << item
  end

  def neighbors(x, y, radius : Int32 = 1) : Array({T, Int32})
    # n = Array(T).new(4 * radius)
    # puts "#{@max_size} #{x}/#{@width-1},#{y}/#{@height-1}  #{x}, #{y + 1} #{y < @height - 1} #{@height - 1}"

    # (1..radius).each do |i|
    #   n << self[x, y - i] if y-i >= 0 # up
    #   n << self[x + i, y] if x < @width - i # right
    #   n << self[x, y + i] if y < @height - i # down
    #   n << self[x - i, y] if x-i >= 0 # left
    # end

    surrounding_offsets = Array({Int32, Int32}).new(4 * radius)
    surrounding_nodes_with_edge_cost = Array({T, Int32}).new(4 * radius)

    (1..radius).each do |r|
      surrounding_offsets << {0, 0-r} if y-r >= 0 # up
      surrounding_offsets << {r,  0} if x < @width - r - 1# right
      surrounding_offsets << {0,  r} if y < @height - r - 1# down
      surrounding_offsets << {0-r, 0} if x-r >= 0 # left
    end

    surrounding_offsets.each do |(ox, oy)|
      heat_sum = 0
      if ox == 0
        (1..oy).each do |oyy|
          node = self[x, oyy + y]
          heat_sum += node.heat_loss
          surrounding_nodes_with_edge_cost << {node, heat_sum}
        end
      else
        (1..ox).each do |oxx|
          node = self[oxx + x, y]
          heat_sum += node.heat_loss
          surrounding_nodes_with_edge_cost << {node, heat_sum}
        end
      end
    end

    surrounding_nodes_with_edge_cost
  end

  def neighbors_radius(x, y, radius)

  end

  def each
    x = 0
    y = 0
    @array.each_with_index do |el, i|
      yield el, x, y
      if x >= @width - 1
        x = 0
        y += 1
      else
        x += 1
      end
    end
  end

  def each_row
    @array.each_slice(@width) { |slice| yield slice }
  end

  def reverse_each_row
    row_start = @width * @height - @width
    while row_start >= 0
      yield @array[row_start, @width]
      row_start -= @width
    end
  end

  def line_values(x1 : Int32, y1 : Int32, x2 : Int32, y2 : Int32) : Array(T)
    is_row = true
    if x1 == x2
      r = x1 < x2 ? x1..x2 : x2..x1
    elsif y1 == y2
      is_row = false
      r = y1 < y2 ? y1..y2 : y2..y1
    else
      raise "rectangles are not supported"
    end

    values = Array(T).new(r.end - r.begin)
    if is_row
      r.each { |x| values << self[x, y1] }
    else
      r.each { |y| values << self[x1, y] }
    end
    values
  end

  def fill(x1, y1, x2, y2, value : T)
    x1, x2 = x2, x1 if x2 < x1
    y1, y2 = y2, y1 if y2 < y1

    (x1..x2).each do |x|
      (y1..y2).each do |y|
        self[x, y] = value
      end
    end

    self
  end

  def select_rect(x1, y1, x2, y2)
    # return a 1d array of all the values in a rectangle
    x1, x2 = x2, x1 if x2 < x1
    y1, y2 = y2, y1 if y2 < y1
    size = (x2 - x1) * (y2 - y1)
    values = Array(T).new(size)
    (y1..y2).each do |y|
      values.concat(@array[(y * @width + x1)..(y * width + x2)])
    end

    values
  end
end
#  0  1  2  3  4
#  5  6  7  8  9
# 10 11 12 13 14

class Matrix3(T)
  getter array, width, height, depth
  def initialize(@width : Int32, @height : Int32, @depth : Int32, default_value : T)
    @max_size = @width * @height * @depth
    @array = Array(T).new(@max_size, default_value)
  end

  def initialize(@width : Int32, @height : Int32, @depth : Int32)
    @max_size = @width * @height * @depth
    @array = Array(T).new(@max_size)
  end

  def [](x : Int32, y : Int32, z : Int32) : T
    offset = (z * @height * @width) + (@width * y) + x
    @array[offset]
  end

  def []=(x : Int32, y : Int32, z : Int32, item : T) : T
    offset = (z * @height * @width) + (@width * y) + x
    @array[offset] = item
  end

  def fill(x1, y1, z1, x2, y2, z2, value : T)
    x1, x2 = x2, x1 if x2 < x1
    y1, y2 = y2, y1 if y2 < y1
    z1, z2 = z2, z1 if z2 < z1
    (x1..x2).each do |x|
      (y1..y2).each do |y|
        (z1..z2).each do |z|
          self[x, y, z] = value
        end
      end
    end

    self
  end

  def layer(z) : Matrix(T)
    layer_start = z * @height * @width
    layer_end = layer_start + @width * @height
    Matrix(T).new(@array[layer_start..layer_end], @width, @height)
  end
end
