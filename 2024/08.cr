require "benchmark"
require "../2023/lib/vector2d"

["inputs/08_test.txt", "inputs/08.txt"].each do |filename|
  # grid = parse(filename)

  p1 = p2 = 0i64

  Benchmark.ips do |bm|
    bm.report { p1 = part1(filename) }
    bm.report { p2 = part2(filename) }
  end
  # p1 = part1(filename)
  # p2 = part2(filename)

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

def part1(filename)
  Grid.new(filename, resonate: false).antinodes.size
end

def part2(filename)
  grid = Grid.new(filename, resonate: true)
  # GridRenderer.new(grid).render
  grid.antinodes.size
end

class Grid
  getter origin : Vector2d(Int32)
  getter max : Vector2d(Int32)
  getter antinodes : Set(Vector2d(Int32))
  getter towers : Hash(Char, Array(Vector2d(Int32)))

  def initialize(filename, resonate = false)
    @towers = Hash(Char, Array(Vector2d(Int32))).new
    @antinodes = Set(Vector2d(Int32)).new

    lines = File.read(filename).lines
    @origin = Vector2d(Int32).new(0, 0)
    @max = Vector2d(Int32).new(lines[0].size - 1, lines.size - 1)
    lines.map_with_index do |line, y|
      line.chars.map_with_index do |char, x|
        next if char == '.'
        set = @towers.has_key?(char) ? @towers[char] : nil
        if set.nil?
          @towers[char] = [Vector2d(Int32).new(x, y)]
        else
          set << Vector2d(Int32).new(x, y)
        end
      end
    end
    find_antinodes(resonate)
  end

  private def find_antinodes(resonate)
    @towers.each do |frequency, list|
      next if list.size == 1
      list.each_permutation(2, reuse: true) do |(t1, t2)|
        antinodes1 = find_opposites(t1, t2, resonate)
        antinodes2 = find_opposites(t2, t1, resonate)
        @antinodes.concat(antinodes1)
        @antinodes.concat(antinodes2)
      end
    end
  end

  def find_opposites(tower1, tower2, resonate)
    diff = tower2 - tower1
    opposites = Array(Vector2d(Int32)).new
    if resonate
      opposite = tower2
      while opposite.contained_by_rect?(@origin, @max)
        opposites << opposite
        opposite = opposite + diff
      end
    else
      opposite = tower2 + diff
      opposites << opposite if opposite.contained_by_rect?(@origin, @max)
    end
    opposites
  end
end

class GridRenderer
  def initialize(@grid : Grid)
  end

  def render
    symbols = Hash({Int32, Int32}, Char).new
    @grid.antinodes.each do |antinode|
      symbols[{antinode.x, antinode.y}] = '#'
    end
    @grid.towers.each do |freq, list|
      list.each do |vec|
        symbols[{vec.x, vec.y}] = freq
      end
    end

    map = String.build((@grid.max.x + 2) * (@grid.max.y + 1)) do |str|
      0.upto(@grid.max.y) do |y|
        0.upto(@grid.max.x) do |x|
          xy = {x, y}
          str << (symbols.has_key?(xy) ? symbols[xy] : '.')
        end
        str << '\n'
      end
    end

    puts map
  end
end
