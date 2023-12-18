require "./lib/cycle_detector"
alias RockMapRow = Array(Char)
alias RockMap = Array(RockMapRow)

["inputs/14_example.txt", "inputs/14.txt"].each do |filename|
  input = load(filename)

  p1 = part1(input)
  puts "#{filename} part 1: #{p1}"

  p2 = part2(input)
  puts "#{filename} part 2: #{p2}"
end

def load(filename) : RockMap
  (File.read(filename).lines.map(&.chars)).as RockMap
end

def part1(input)
  modified_input = slide(input, :north)
  # puts modified_input.map(&.join).join("\n")
  calculate_load(modified_input, :north)
end

def part2(input)
  start = Time.utc
  runs = 1000000000
  sequence_length, sequence_start, sequence_values = detect_cycles(input)

  idx = (runs - sequence_start) % sequence_length
  final_state = sequence_values[idx + sequence_start - 1]

  # sequence_values.each do |rock_map|
  #   puts "\n\n" + rock_map.map(&.join).join("\n")
  #   puts "load: #{calculate_load(rock_map, :north)}"
  # end
  calculate_load(final_state, :north)
end

def spin(input)
  [:north, :west, :south, :east].each do |direction|
    input = slide(input, direction)
    # puts "\n\n" + input.map(&.join).join("\n")
  end
  input
end

def detect_cycles(input)
  CycleDetector(RockMap).find(input) { |x| spin(x) }
end

def slide(input, direction)
  input = input.transpose if direction == :north || direction == :south

  input = input.map do |line|
    line = line.reverse if direction == :south || direction == :east

    line = split(line, '#').map do |group|
      if group.size == 1 && group[0] == '#'
        group
      else
        group.sort.reverse
      end
    end.flatten

    if direction == :south || direction == :east
      line.reverse
    else
      line
    end
  end

  input = input.transpose if direction == :north || direction == :south
  input
end

def split(line : RockMapRow, split_char : Char)
  array = [[] of Char]
  line.each do |char|
    if char == split_char
      array << [split_char]
      array << [] of Char
    else
      array.last << char
    end
  end

  array
end

def calculate_load(input, direction)
  max_load_per = (direction == :north || direction == :south) ? input.size : input[0].size
  input = input.transpose if direction == :west || direction == :east

  input.each_with_index.reduce(0) do |acc, (line, i)|
    line = line.reverse if direction == :south || direction == :east
    load = max_load_per - i
    line_sum = line.reduce(0) {|acc2, char| acc2 + (char == 'O' ? load : 0) }
    acc + line_sum
  end
end
