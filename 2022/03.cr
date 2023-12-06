test_input = "vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw"

puts "azAZ".codepoints

def priority_map
  start_lowercase = 97
  end_lowercase = start_lowercase + 25
  start_uppercase = 65
  end_uppercase = 90
  priorities = Hash(Char, Int32).new

  (start_lowercase..end_lowercase).each do |codepoint|
    priority = codepoint - 96
    priorities[codepoint.chr] = priority
  end
  (start_uppercase..end_uppercase).each do |codepoint|
    priority = codepoint - 38
    priorities[codepoint.chr] = priority
  end

  priorities
end

def part_one(input)
  priorities = priority_map()

  all_fdsa = input.lines.map do |line|
    midpoint = (line.size / 2).to_i
    compartment_1 = line[0...midpoint]
    compartment_2 = line[midpoint..]
    (compartment_1.codepoints & compartment_2.codepoints).map &.chr
  end.flatten

  all_fdsa.reduce(0) { |acc, letter| acc + priorities[letter]}
end

def part_two(input)
  priorities = priority_map()
  group_sums = input.lines.in_groups_of(3, "").map do |group|
    common = group.reduce(group.first.codepoints) { |acc, i| acc & i.codepoints }
    common.reduce(0) { |acc, codepoint| acc + priorities[codepoint.chr] }
  end.flatten
  group_sums.sum
end

puts part_one(test_input)
puts part_one(File.read("inputs/03.txt"))

puts "---"
puts part_two(test_input)
puts part_two(File.read("inputs/03.txt"))