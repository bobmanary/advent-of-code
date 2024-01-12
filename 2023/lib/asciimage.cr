require "./matrix"

class Asciimage
  delegate :[], :[]=, to: @matrix
  getter matrix

  def initialize(@width : Int32, @height : Int32)
    @matrix = Matrix(Char).new(@width, @height, ' ')
  end

  def initialize(@matrix : Matrix(Char))
    @width = @matrix.width
    @height = @matrix.height
  end

  def initialize(other : Asciimage)
    @width = other.matrix.width
    @height = other.matrix.height
    array = other.matrix.array.dup
    @matrix = Matrix(Char).new(array, @width, @height)
  end


  def plot(x, y, char)
    @matrix[x, y] = char
    self
  end

  def [](y)
    line_start = y * @width
    line_end = ((y+1) * @width) - 1
    @matrix.array[line_start..line_end]
  end

  def fill(x1, y1, x2, y2, char)
    @matrix.fill(x1, y1, x2, y2, char)
    self
  end

  def flood_fill(x, y, old_char, new_char)
    return if x < 0 || x >= @width || y < 0 || y  >= @height
    return if self[x, y] != old_char
    self[x, y] = new_char
    flood_fill(x+1, y, old_char, new_char)
    flood_fill(x-1, y, old_char, new_char)
    flood_fill(x, y+1, old_char, new_char)
    flood_fill(x, y-1, old_char, new_char)
    self
  end

  def as_string(flip)
    String.build do |io|
      if flip
        @matrix.each_row do |row|
          row.each do |char|
            io << char
          end
          io << "\n"
        end
      else
        @matrix.reverse_each_row do |row|
          row.each do |char|
            io << char
          end
          io << "\n"
        end
      end
    end
  end

  def render(flip : Bool = false)
    puts as_string(flip)
  end
end
