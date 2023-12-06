EXAMPLE = "2-4,6-8
2-3,4-5
5-7,7-9
2-8,3-7
6-6,4-6
2-6,4-8"

input = File.read("inputs/04.txt")

def part_one(input)
  elf_sections = [] of Array(Range(Int32, Int32))
  input.lines.each do |line|
    ranges = line.split(',').map do |range_str|
      r = range_str.split('-').map &.to_i
      Range.new(r.min, r.max)
    end
    elf_sections << [ranges.first, ranges.last]
  end

  default_elf = [-1..-1, -1..-1]

  elf_sections.in_groups_of(2, default_elf).select do |pair|
    (
      overlap?(pair.first.first, pair.last.first) ||
      overlap?(pair.first.first, pair.last.last) ||
      overlap?(pair.first.last, pair.last.first) ||
      overlap?(pair.first.last, pair.last.last)
    )
  end

  # ranges.in_groups_of(2, default_elf).select do |pair|
  #   pair.
  # end
  # puts ranges
end

def overlap?(range_1, range_2)
  (range_1.includes?(range_2.begin) && range_1.includes?(range_2.end)) ||
  (range_2.includes?(range_1.begin) && range_2.includes?(range_1.end))
end

puts part_one(EXAMPLE)