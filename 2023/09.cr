#
["inputs/09_example.txt", "inputs/09.txt"].each do |filename|
  inputs = File.read(filename).lines
    .map(&.split)
    .map { |l| l.map(&.to_i) }

  puts "#{filename} part 1: #{part1(inputs)}"
  puts "#{filename} part 2: #{part2(inputs)}"
end

def part1(inputs)
  inputs.reduce(0) do |acc, value_history|
    stack = build_differences(value_history)

    reverse_each(stack) do |smaller, larger|
      larger << smaller.last + larger.last
    end

    acc + stack.first.last
  end
end

def part2(inputs)
  inputs.reduce(0) do |acc, value_history|
    stack = build_differences(value_history)

    reverse_each(stack) do |smaller, larger|
      larger.unshift larger.first - smaller.first
    end

    acc + stack.first.first
  end
end

def reverse_each(a : Array)
  i = a.size - 1
  while i > 0
    yield(a[i], a[i-1])
    i -= 1
  end
end

def build_differences(value_history)
  stack = [value_history.clone]
  while true
    current_list = stack.last
    new_list = Array(Int32).new(current_list.size)
    (current_list.size - 1).times do |i|
      new_list << current_list[i+1] - current_list[i]
    end
    stack << new_list
    break if new_list.all?(&.zero?)
  end

  stack
end