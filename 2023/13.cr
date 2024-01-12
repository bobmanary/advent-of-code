DEBUG = false
["inputs/13_example.txt", "inputs/13.txt"].each do |filename|
  input = load(filename)
  p1 = part1(input)
  p2 = part2(input)

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

def load(filename)
  File.read(filename).split("\n\n").map do |pattern_str|
    pattern_str.lines.map(&.chars)
  end
end

def part1(input)
  input.reduce(0) do |acc, pattern|
    sym = find_symmetry(pattern)
    if sym[0] == :none
      raise "Oh no! Could not find symmetry:\n#{pattern.join("\n")}"
    end
    acc + calc_summary(pattern, sym[0], sym[1])
  end
end

def part2(input)
  input.reduce(0) do |acc, pattern|
    original_symmetry = find_symmetry(pattern)

    # brute forcing every possible pattern change is fast enough here
    each_potential_smudge(pattern) do |modified_pattern, modx, mody|
      sym = find_symmetry(modified_pattern)
      next if sym[0] == :none || sym == original_symmetry

      # print_pattern(modified_pattern, sym[0], sym[1])
      # puts "original: #{original_symmetry[0]} #{original_symmetry[1]}"
      # puts "     new: #{sym[0]} #{sym[1]}"
      # puts "(smudge at #{modx},#{mody})\n\n"

      acc += calc_summary(modified_pattern, sym[0], sym[1])
      break
    end
    acc
  end
end

def print_pattern(pattern, symmetry_direction, sym_position)
  pattern.each_with_index do |row, y|
    print row.join
    if symmetry_direction == :vertical && y == sym_position
      print " v"
    elsif symmetry_direction == :vertical && y == (sym_position + 1)
      print " ^"
    end
    print '\n'
  end

  if symmetry_direction == :horizontal
    print " " * sym_position
    print "><\n"
  end
end

def each_potential_smudge(pattern)
  # mutates pattern
  pattern.each_with_index do |row, y|
    row.each_with_index do |char, x|
      original_cell = pattern[y][x]
      smudged_cell = original_cell == '#' ? '.' : '#'
      pattern[y][x] = smudged_cell

      # puts "changing #{original_cell} to #{smudged_cell} at #{x},#{y}"
      # puts pattern.map(&.join).join("\n")
      yield pattern, x, y
      pattern[y][x] = original_cell
    end
  end
end

def find_symmetry(pattern)
  width = pattern[0].size
  height = pattern.size
  across_horizontal = true
  across_vertical = true
  maybe_horizontal = Array(Bool).new(width - 1, true)
  maybe_vertical = Array(Bool).new(height - 1, true)

  (0...height).each do |y|
    (0..width-2).each do |x|
      next unless maybe_horizontal[x]
      unless symmetrical_from_offset?(pattern[y], x, width)
        maybe_horizontal[x] = false
      end
    end
    dputs "--"
  end

  dputs "----"
  (0...width).each do |x|
    (0..height-2).each do |y|
      next unless maybe_vertical[y]
      unless symmetrical_from_offset?(v_slice(pattern, x), y, height)
        maybe_vertical[y] = false
      end
    end
    dputs "--"
  end

  # puts maybe_horizontal
  # puts maybe_vertical

  if maybe_vertical.any?
    return {:vertical, maybe_vertical.index!(true)}
  end
  if maybe_horizontal.any?
    return {:horizontal, maybe_horizontal.index!(true)}
  end

  {:none, -1}
end


def v_slice(pattern, x)
  pattern.map { |row| row[x] }
end

def symmetrical_from_offset?(slice, start_index, length)
  cell1 = start_index
  cell2 = start_index + 1

  while cell1 >= 0 && cell2 < length
    dputs "#{cell1}:#{slice[cell1]} #{cell2}:#{slice[cell2]}"
    return false if slice[cell1] != slice[cell2]
    cell1 -= 1
    cell2 += 1
  end

  true
end

def calc_summary(pattern, symmetry_direction, start_index)
  if symmetry_direction == :horizontal
    start_index + 1
  else
    (start_index + 1) * 100
  end
end

def dputs(msg)
  if DEBUG
    puts msg
  end
end
