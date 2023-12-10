# this implementation takes a minute or so for part 2
# when built in release mode or 11+ in debug mode
class SeedMapper
  def initialize(@maps : Array(SparseCategoryMap))
  end

  def find_location(seed_id : UInt64) : UInt64
    @maps.reduce(seed_id) do |next_id, map|
      map.fetch(next_id)
    end
  end
end

class CategoryMapSegment
  getter source : UInt64
  getter dest : UInt64
  getter length : UInt64
  def initialize(@source, @dest, @length)
  end
end

class SparseCategoryMap
  getter name

  def initialize(@name : String)
    @segments = [] of CategoryMapSegment
  end

  def add(src_start : UInt64, dest_start : UInt64, length : UInt64)
    @segments << CategoryMapSegment.new(src_start, dest_start, length)
  end

  def fetch(id)
    found = @segments.find do |segment|
      id >= segment.source && id < segment.source + segment.length
    end

    return id if found.nil?

    offset = id - found.source
    found.dest + offset
  end
end

["inputs/05_example.txt", "inputs/05.txt"].each do |filename|
  input = File.read(filename).lines.each
  seeds_str = input.next
  raise "wat" unless seeds_str.is_a?(String)

  # parse
  seeds = seeds_str.partition(": ").last.split.map(&.to_u64)
  current_map = SparseCategoryMap.new("")
  maps = [] of SparseCategoryMap

  while (line = input.next).is_a?(String)
    next if line.empty?

    if line[0] >= '0' && line[0] <= '9'
      ranges = line.split.map(&.to_u64)
      dest = ranges[0]
      src = ranges[1]
      length = ranges[2]

      current_map.add(src, dest, length)
    else
      current_map = SparseCategoryMap.new(line)
      maps << current_map
    end
  end

  # find results
  mapper = SeedMapper.new(maps)
  lowest_location_number = seeds.map do |seed|
    mapper.find_location(seed)
  end.min
  puts "#{filename} part 1: #{lowest_location_number}"

  lowest_location_number2 = UInt64::MAX
  seeds.in_groups_of(2, 0u64) do |(start, length)|
    (start...start+length).each do |seed|
       loc = mapper.find_location(seed)
       lowest_location_number2 = loc if loc < lowest_location_number2
    end
  end
  puts "#{filename} part 2: #{lowest_location_number2}"
end
