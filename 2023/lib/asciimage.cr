class Asciimage
  def initialize(@width : Int32, @height : Int32)
    @matrix = Matrix(Char).new(@width, @height, ' ')
  end

  def plot(x, y, char)
    @matrix[x, y] = char
  end

  def as_string
    s = String.build do |io|
      @matrix.each_row do |row|
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
