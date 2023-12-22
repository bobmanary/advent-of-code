class Matrix(T)
  getter array : Array(T)
  def initialize(@width : Int32, @height : Int32, default_value : T? = nil)
    @max_size = @width * @height
    if default_value
      @array = Array(T).new(@max_size, default_value)
    else
      @array = Array(T).new(@max_size)
    end
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

  def neighbors(x, y) : Array(T)
    n = Array(T).new(4)
    # puts "#{@max_size} #{x}/#{@width-1},#{y}/#{@height-1}  #{x}, #{y + 1} #{y < @height - 1} #{@height - 1}"
    
    n << self[x, y - 1] if y > 0 # up
    n << self[x + 1, y] if x < @width - 1 # right
    n << self[x, y + 1] if y < @height - 1 # down
    n << self[x - 1, y] if x > 0 # left

    n
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
end

#  0  1  2  3  4
#  5  6  7  8  9
# 10 11 12 13 14