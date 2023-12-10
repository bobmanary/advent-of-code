def part1(time_limits : Array(UInt64), distances : Array(UInt64))
  results = [] of UInt64

  time_limits.each_with_index do |limit, i|
    winning_ways = 0u64
    (1...limit).each do |held_time|
      movement_time = limit - held_time
      distance_traveled = movement_time * held_time

      if distance_traveled > distances[i]
        winning_ways += 1
      end
    end

    results << winning_ways
  end

  results.reduce(1) { |acc, result| acc * result }
end

["inputs/06_example.txt", "inputs/06.txt"].each do |filename|
  input = File.read(filename).lines

  time_limits = input[0].split(':').last.split.map(&.to_u64)
  distances = input[1].split(':').last.split.map(&.to_u64)

  time_limit2 = [input[0].split(':').last.split.join.to_u64]
  distance2 = [input[1].split(':').last.split.join.to_u64]

  puts "#{filename} part 1: #{part1(time_limits, distances)}"
  puts "#{filename} part 2: #{part1(time_limit2, distance2)}"
end
