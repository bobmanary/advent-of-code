["inputs/12_example.txt"].each do |filename|
  input = parse(File.read(filename))
  
  p1 = part1(input)
  puts "#{filename} part 1: #{p1}"

  p2 = part2(input)
  puts "#{filename} part 2: #{p2}"
end


def parse(input)
  input.lines.map do |line|
    r, g = line.split(' ')
    row = r.chars
    groups = g.split(',').map(&.to_i)
    {row, groups}
  end
end

def part1(input)
  input.reduce(0) do |total, records|
    result = permute2(records[0], 0, records[1], {"count" => 0, "iterations" => 0u64})
    total += result["count"]
  end
end

def part2(input)
  input2 = input.map do |records|
    row = records[0].clone
    count_groups = records[1] * 5
    4.times do
      row << '?'
      row.concat(records[0])
    end
    {row, count_groups}
  end
  part1(input2)
end

#    ?###???????? 3,2,1
def permute2(row : Array(Char), start : Int32, damaged_group_sizes : Array(Int32), found)
  permutation_count = 0
  found_count = 0
  i = row.index('?', start)

  if i.is_a?(Int32)
    ['.', '#'].each do |potential_char|
      found["iterations"] += 1u64
      row[i] = potential_char
      permute2(row, i+1, damaged_group_sizes, found)
    end
    row[i] = '?'
  else
    # all ? symbols have been converted
    p_damage = find_damaged_group_sizes(row) # check if [1,2] == [3,2,1]
    if p_damage == damaged_group_sizes
      found["count"] = found["count"] + 1
      puts "        #{row.join}  #{p_damage.join(',')}   #{found["count"]}"
    end
  end

  if found["iterations"] % 1000000 == 0
    puts "Iterations: #{found["count"]}/#{found["iterations"]} #{row.join}"
  end

  found
end

def find_unknown_positions(row)
  positions = [] of Int32
  row.each_with_index do |char, i|
    positions << i if char == '?'
  end
  positions
end

def permute3(records)
  row = records[0]
  groups = records[1]
  length = row.size
  permutations_by_starting_position = []

  i = 0
  while i < length
    if row[i] == '?'
    end
  end
end

def permute(row : Array(Char), damaged_group_sizes : Array(Int32))
  r2 = row.clone
  total_damaged = damaged_group_sizes.sum
  min_damaged = r2.reduce(0) { |acc, char| acc + (char == '#' ? 1 : 0) }
  unknown_to_damaged = total_damaged - min_damaged
  r2.each_with_index do |char, i|
    if char == '?'
      if unknown_to_damaged > 0
        unknown_to_damaged -= 1
        r2[i] = '#'
      else
        r2[i] = '.'
      end
    end
  end
  permutations = Set(String).new
  iterations = found = 0u64
  puts ""

  r2.each_permutation(reuse: true) do |permutation|
    iterations += 1
    # reject permutations that don't match the original known pattern
    match = true
    row.each_with_index do |char, i|
      if char != '?' && char != permutation[i]
        match = false
      end
    end
    if match && find_damaged_group_sizes(permutation) == damaged_group_sizes
      found += 1
      permutations << permutation.join
    end

    if iterations % 1000000 == 0
      print "\r#{iterations}, #{found}, #{permutations.size}, #{permutation.join}"
    end
  end
  puts ""
  permutations
end

def find_damaged_group_sizes(pattern)
  group_size = 0
  groups = [] of Int32
  pattern.each do |char|
    if char == '.'
      if group_size > 0
        groups << group_size
        group_size = 0
      end
    else
      group_size += 1
    end
  end
  if group_size > 0
    groups << group_size
  end
  groups
end

