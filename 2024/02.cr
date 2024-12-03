["inputs/02_test.txt", "inputs/02.txt"].each do |filename|
  input = parse(filename)
  puts "#{filename} part 1: #{part1(input)}"
  puts "#{filename} part 2: #{part2(input)}"
end

def parse(filename) : Array(Array(Int32))
  File.read(filename).lines.map do |line|
    line.split().map &.to_i
  end
end

def safe?(report)
  increasing = report[0] < report[1]
  safe = true
  report.each.cons_pair.each do |a, b|
    diff = a > b ? a - b : b - a
    if increasing && a > b || !increasing && a < b
      safe = false
      break
    end
    if diff < 1 || diff > 3
      safe = false
      break
    end
  end

  safe
end

def variations(report)
  new_reports = [] of Array(Int32)
  report.size.times do |skip_index|
    arr = [] of Int32
    report.each_with_index do |num, i|
      arr << num if skip_index != i
    end
    new_reports << arr
  end

  new_reports
end

def part1(reports)
  reports.count do |report|
    safe?(report)
  end
end

def part2(reports)
  reports.count do |report|
    if safe?(report)
      true
    else
      variations(report).any? do |variant|
        safe?(variant)
      end
    end
  end
end