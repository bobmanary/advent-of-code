require "./matrix"
class Asciimage
  def initialize(@width : Int32, @height : Int32)
    @matrix = Matrix(Char).new(@width, @height, ' ')
  end

  def plot(x, y, char)
    @matrix[x, y] = char
    self
  end

  def fill(x1, y1, x2, y2, char)
    @matrix.fill(x1, y1, x2, y2, char)
    self
  end

  def as_string
    String.build do |io|
      @matrix.reverse_each_row do |row|
        row.each do |char|
          io << char
        end
        io << "\n"
      end
    end
  end

  def render
    puts as_string
  end
end
