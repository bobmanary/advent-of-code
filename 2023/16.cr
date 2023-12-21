
["inputs/16_example.txt", "inputs/16.txt"].each do |filename| #
  grid = Grid.load(filename)
  grid.trace_beams(Beam.new(0, 0, Direction::Right))

  puts "#{filename} part 1: #{grid.count_energized_cells}"
  puts "#{filename} part 2: #{part2(grid)}"
end

def part2(grid)
  most_energized = 0
  starting_positions = Array(Beam).new((grid.max_x*2) + (grid.max_y*2))
  (0..grid.max_y).each do |y|
    starting_positions << Beam.new(0, y, Direction::Right)
    starting_positions << Beam.new(grid.max_x, y, Direction::Left)
  end
  (0..grid.max_x).each do |x|
    starting_positions << Beam.new(x, 0, Direction::Down)
    starting_positions << Beam.new(x, grid.max_y, Direction::Up)
  end

  starting_positions.reduce(0) do |max, beam|
    energized = grid.trace_beams(beam).count_energized_cells
    energized > max ? energized : max
  end
end

enum Direction
  Up
  Right
  Down
  Left
end

enum CellType
  SplitterV # |
  SplitterH # -
  Mirror45 # /
  Mirror135 # \
  Empty # .
end

class Grid
  getter max_x : Int32
  getter max_y : Int32

  def self.load(filename)
    cells = File.read(filename).lines.map do |line|
      line.chars.map do |char|
        type = case char
        when '|' then CellType::SplitterV
        when '-' then CellType::SplitterH
        when '/' then CellType::Mirror45
        when '\\' then CellType::Mirror135
        when '.' then CellType::Empty
        else
          raise "Unknown symbol #{char}"
        end
        Cell.new(type)
      end
    end

    new(cells)
  end

  def initialize(@cells : Array(Array(Cell)))
    @max_x = @cells[0].size - 1
    @max_y = @cells.size - 1
  end

  def reset
    @cells.each do |row|
      row.each do |cell|
        cell.energized = 0
      end
    end
  end

  def trace_beams(starting_beam : Beam)
    reset
    visited_cells = Set(Int32).new(@max_x * @max_y * 4)
    active_beams = [starting_beam]

    while active_beams.size > 0
      beam = active_beams.pop

      while true
        if beam.x > @max_x || beam.x < 0 || beam.y > @max_y || beam.y < 0
          # this beam went out of bounds
          break
        end
        unless visited_cells.add?(beam.hash)
          break
        end
        # render
        # sleep 0.003

        cell = @cells[beam.y][beam.x]
        cell.energized += 1

        case cell.type
        in CellType::SplitterV # |
          case beam.dir
          in Direction::Right, Direction::Left
            active_beams << Beam.new(beam.x, beam.y + 1, Direction::Down)
            beam.y -= 1
            beam.dir = Direction::Up
          in Direction::Up, Direction::Down
            beam.y += beam.dir == Direction::Up ? -1 : 1
          end
        in CellType::SplitterH # -
          case beam.dir
          in Direction::Up, Direction::Down
            active_beams << Beam.new(beam.x + 1, beam.y, Direction::Right)
            beam.x -= 1
            beam.dir = Direction::Left
          in Direction::Right, Direction::Left
            beam.x += beam.dir == Direction::Left ? -1 : 1
          end
        in CellType::Mirror45 # /
          case beam.dir
          in Direction::Up
            beam.dir = Direction::Right
            beam.x += 1
          in Direction::Right
            beam.dir = Direction::Up
            beam.y -= 1
          in Direction::Down
            beam.dir = Direction::Left
            beam.x -= 1
          in Direction::Left
            beam.dir = Direction::Down
            beam.y += 1
          end
        in CellType::Mirror135 # \
          case beam.dir
          in Direction::Up
            beam.dir = Direction::Left
            beam.x -= 1
          in Direction::Right
            beam.dir = Direction::Down
            beam.y += 1
          in Direction::Down
            beam.dir = Direction::Right
            beam.x += 1
          in Direction::Left
            beam.dir = Direction::Up
            beam.y -= 1
          end
        in CellType::Empty
          case beam.dir
          in Direction::Up
            beam.y -= 1
          in Direction::Right
            beam.x += 1
          in Direction::Down
            beam.y += 1
          in Direction::Left
            beam.x -= 1
          end
        end
      end
    end

    self
  end

  def render
    @cells.each do |row|
      chars = [] of Char
      row.each do |cell|
        ascii = case cell.type
        in CellType::SplitterV
          '|'
        in CellType::SplitterH
          '-'
        in CellType::Mirror45
          '/'
        in CellType::Mirror135
          '\\'
        in CellType::Empty
          '.'
        end
        if cell.type == CellType::Empty
          if cell.energized > 1
            ascii = cell.energized.to_s.chars[-1]
          elsif cell.energized == 1
            ascii = '#'
          end
        end
        chars << ascii
      end
      puts chars.join

    end
  end

  def count_energized_cells
    @cells.reduce(0) do |acc, row|
      acc + row.reduce(0) { |acc2, cell| acc2 + (cell.energized? ? 1 : 0) }
    end
  end
end

class Cell
  property type
  property energized = 0

  def initialize(@type : CellType)
  end

  def energized?
    @energized > 0
  end
end

class Beam
  property dir : Direction
  property x : Int32
  property y : Int32
  def initialize(@x, @y, @dir)
  end

  def hash
    (@x << 17) + (y << 2) + @dir.value
  end
end