require "benchmark"

["inputs/07_test.txt", "inputs/07.txt"].each do |filename|
  calibrations = parse(filename)

  p1 = p2 = 0i64

  Benchmark.ips do |bm|
    bm.report { p1 = part1(calibrations) }
    bm.report { p2 = part2(calibrations) }
  end
  # p1 = part1(calibrations)
  # p2 = part2(calibrations)

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end


def parse(filename)
  File.read(filename).lines.map do |line|
    nums = line.split(/\D+/).map &.to_i64
    {expected: nums[0], operands: nums[1..]}
  end
end

def part1(calibrations)
  reduce(calibrations, false)
end

def part2(calibrations)
  reduce(calibrations, true)
end

def reduce(calibrations, concat_operator)
  calibrations.reduce(0i64) do |total_result, calibration|
    if calc(calibration[:operands][0], calibration[:operands], 1, calibration[:operands].size - 1, calibration[:expected], concat_operator)
      total_result + calibration[:expected]
    else
      total_result
    end
  end
end

def calc(ongoing_result, operands, op_index, op_max, expected_result, concat_operator)
  if op_index > op_max
    return ongoing_result == expected_result
  end
  return true if calc(ongoing_result * operands[op_index], operands, op_index + 1, op_max, expected_result, concat_operator) 
  return true if calc(ongoing_result + operands[op_index], operands, op_index + 1, op_max, expected_result, concat_operator)
  if concat_operator
    return true if calc(
      concat(ongoing_result, operands[op_index]),
      operands, op_index + 1, op_max, expected_result, concat_operator
    )
  end
  false
end

def concat(a, b)
  magnitude = 1
  loop do
    if magnitude > b
      break
    else
      magnitude *= 10
    end
  end
  a * magnitude + b
end
