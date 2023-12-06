example_schematic = "467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598.."

abstract class GridElement
  property width : Int32 = 1
  abstract def to_s
  def symbol?
    false
  end

  def number?
    false
  end
end

class SchematicNumber < GridElement
  property is_part_number : Bool = false
  property number : Int32

  def initialize(@number, width)
    @width = width
  end

  def to_s
    @number
  end

  def number?
    true
  end
end

class SchematicSymbol < GridElement
  property symbol : Char
  property adjacent_part_numbers : Set(SchematicNumber)

  def initialize(@symbol)
    @adjacent_part_numbers = Set(SchematicNumber).new
  end

  def to_s
    @symbol
  end

  def symbol?
    true
  end
end

class SchematicGrid
  property width : Int32
  property height : Int32
  property grid : Array(Array(GridElement?))

  def initialize(@width, @height)
    @grid = Array(Array(GridElement?)).new
    @height.times do |y|
      row = Array(GridElement?).new(@width, nil)
      @grid << row
    end
  end

  def add_element(el : SchematicNumber | SchematicSymbol, x : Int32, y : Int32)
    # puts "adding element #{el.to_s} at #{x},#{y} to #{x.to_i32+el.width-1},#{y}"
    el.width.times do |i|
      @grid[y][x + i] = el
    end
  end

  def to_s
    @grid
  end

  def each_occupied_grid_coord(&block)
    serial_offset = 0
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        next unless cell.is_a?(SchematicNumber)
        yield(cell, x, y, serial_offset)
        serial_offset += 1
      end
      serial_offset = 0
    end
  end

  def each_symbol(&block)
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        next unless cell.is_a?(SchematicSymbol)
        yield(cell)
      end
    end
  end

  def analyze_adjacency
    each_number do |number_element, x, y, width|
      coords = [] of {Int32, Int32}
      coords.push({x-1, y-1}, {x-1, y}, {x-1, y+1}) # left edge
      coords.push({x+number_element.width, y-1}, {x+number_element.width, y}, {x+number_element.width, y+1}) # right edge
      (width).times do |x_offset| # middle
        coords.push({x+x_offset, y-1}, {x+x_offset, y+1})
      end

      # puts "#{x},#{y} #{width} => #{coords}"

      coords.each do |c|
        cx = c[0]
        cy = c[1]
        next if cx < 0 || cx >= @width || cy < 0 || cy >= @height

        adjacent_element = @grid[cy][cx]
        if adjacent_element && adjacent_element.is_a?(SchematicSymbol)
          # puts "#{cx},#{cy} => #{adjacent_element.to_s} for #{number_element.number} at #{x},#{y}"
          number_element.is_part_number = true
          if adjacent_element.symbol == '*'
            adjacent_element.adjacent_part_numbers << number_element
            # puts "...and symbol is *, count: #{adjacent_element.adjacent_part_numbers.size}"
          end
          break
        end
      end
    end
  end

  def each_number(&block)
    current_number : SchematicNumber? = nil
    each_occupied_grid_coord do |cell, x, y|
      next if !cell.try(&.number?) || current_number == cell
      current_number = cell
      yield current_number, x, y, cell.width
    end
  end

  def each_valid_part_number(&block)
    each_number do |cell, x, y, width|
      next if !cell.is_part_number
      yield cell, x, y, width
    end
  end
end

class EngineSchematic
  def initialize(text)
    width = text.each_line.first.size
    height = text.each_line.size
    # puts "grid size: #{width}*#{height}"
    @grid = SchematicGrid.new(width, height)

    parsing_number = false
    number = ""
    number_x_start = 0
    number_x_end = 0

    text.each_line.each_with_index do |line, y|
      line.each_char_with_index do |char, x|
        # puts "#{x},#{y}"
        if numeric?(char)
          if !parsing_number
            number_x_start = x
            parsing_number = true
          end
          # puts "  #{number} + #{char}"
          number = "#{number}#{char}"
        else
          if parsing_number
            number_x_end = x
            parsing_number = false
            n = SchematicNumber.new(number.to_i, number_x_end - number_x_start)
            @grid.add_element(n, number_x_start, y)
            # puts "encountered #{number} at #{x},#{y}, columns #{number_x_start}-#{number_x_end}"
            number = ""
          end
          if symbol?(char)
            @grid.add_element(SchematicSymbol.new(char), x, y)
          end
        end
      end
      if parsing_number
        number_x_end = width - 1
        parsing_number = false
        n = SchematicNumber.new(number.to_i, number_x_end - number_x_start)
        @grid.add_element(n, number_x_start, y)
        # puts "encountered #{number} at #{number_x_start},#{y}, columns #{number_x_start}-#{number_x_end}"
        number = ""
      end
      # puts "next line"
    end
    @grid.analyze_adjacency
  end

  def numeric?(char : Char)
    char >= '0' && char <= '9' 
  end

  def symbol?(char : Char)
    !numeric?(char) && char != '.'
  end

  def sum_part_numbers
    sum = 0
    @grid.each_valid_part_number do |part_number|
      sum += part_number.number
    end
    sum
  end

  def sum_gear_ratios
    sum = 0
    @grid.each_symbol do |s|
      if s.adjacent_part_numbers.size == 2
        sum += s.adjacent_part_numbers.map(&.number).reduce(1) do |a, b| a*b end
      end
    end
    sum
  end
end

test_schematic = EngineSchematic.new(example_schematic)
puts "sum of part numbers: #{test_schematic.sum_part_numbers}"
puts "sum of gear ratios: #{test_schematic.sum_gear_ratios}"

schematic = EngineSchematic.new(File.read("inputs/03.txt"))
puts "sum of part numbers: #{schematic.sum_part_numbers}"
puts "sum of gear ratios: #{schematic.sum_gear_ratios}"