require "benchmark"

["inputs/04_test.txt", "inputs/04.txt"].each do |filename|
  wordsearch = parse(filename)
  p1 = p2 = 0
  Benchmark.ips do |bm|
    bm.report {p1 = part1(wordsearch)}
    bm.report {p2 = part2(wordsearch)}
  end
  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

def parse(filename) : Array(Array(Char))
  File.read(filename).lines.map &.chars
end

def find_direction(chars : Array(Array(Char)), x, y, x_offset, y_offset)
  x_max = chars[0].size - 1
  y_max = chars.size - 1
  string = [] of Char
  4.times do |i|
    break if x < 0 || y < 0 || x > x_max || y > y_max
    string << chars[y][x]
    x += x_offset
    y += y_offset
  end
  string
end

def find(chars : Array(Array(Char)), x, y)
  strings = [] of Array(Char)
  # right
  x_offset = 1
  y_offset = 0
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # down right
  y_offset = 1
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # down
  x_offset = 0
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # down left
  x_offset = -1
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # left
  y_offset = 0
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # up left
  y_offset = -1
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # up
  x_offset = 0
  strings << find_direction(chars, x, y, x_offset, y_offset)
  # up right
  x_offset = 1
  strings << find_direction(chars, x, y, x_offset, y_offset)
  strings.count do |string|
    string == ['X', 'M', 'A', 'S']
  end
end

def part1(chars)
  count = 0
  chars.each_with_index do |line, y|
    line.each_with_index do |char, x|
      next unless char == 'X'
      count += find(chars, x, y)
    end
  end
  count
end

def part2(chars)
  count = 0
  chars.each_with_index do |line, y|
    next if y == 0 || y == chars.size - 1
    line.each_with_index do |char, x|
      next if x == 0 || x == line.size - 1
      next unless char == 'A'
      tl = chars[y-1][x-1] # top left
      tr = chars[y-1][x+1] # top right
      bl = chars[y+1][x-1] # bottom left
      br = chars[y+1][x+1] # bottom right
      if (
        ((tl == 'M' && br == 'S') || (tl == 'S' && br == 'M')) &&
        ((tr == 'M' && bl == 'S') || (tr == 'S' && bl == 'M'))
      )
        count += 1
      end
    end
  end
  count
end
