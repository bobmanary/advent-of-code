["inputs/01_test.txt", "inputs/01.txt"].each do |filename|
  ints = parse(filename)
  ints[0].sort!
  ints[1].sort!
  sum = 0
  similarity = 0
  similarity_counts = ints[1].group_by {|num| num}.transform_values {|v| v.size}

  ints[0].each_with_index do |a, i|
    b = ints[1][i]
    sum += (a > b ? a - b : b - a)
    similarity += a * similarity_counts.fetch(a, 0)
  end

  puts "#{filename} part1: #{sum}"
  puts "#{filename} part2: #{similarity}"
end

def parse(filename) : {Array(Int32), Array(Int32)}
  left = [] of Int32
  right = [] of Int32
  File.read(filename).lines.each do |line|
    ints = line.split()
    left << ints[0].to_i
    right << ints[1].to_i
  end

  {left, right}
end
