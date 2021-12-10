test = "forward 5
down 5
forward 8
up 3
down 8
forward 2"

def each_line(io)
  io.each_line.map do |line|
    distance = line[line.index(" ")..].to_i
    direction = line[0]
    x = direction == 'f' ? distance : 0
    y = case direction
      when 'u' then -distance
      when 'd' then distance
      else 0
      end

    {x, y}
  end.to_a
end
movements = each_line(File.open("inputs/02.txt"))

destination = movements.reduce({0,0}) do |(nx, ny), (mx, my)|
  {nx + mx, ny + my}
end
puts destination
puts destination[0] * destination[1]

test_movements = each_line(test)

def part2_reduce(movements)
  movements.reduce({0, 0, 0}) do |(acc_forward, acc_depth, acc_aim), (change_forward, change_depth)|
    puts "#{{acc_forward, acc_depth, acc_aim}} | #{{change_forward, change_depth}}"
    acc_aim += change_depth
    acc_forward += change_forward
    acc_depth += acc_aim * change_forward

    {acc_forward, acc_depth, acc_aim}
  end
end

puts "part 2 test"
aim_test = part2_reduce(test_movements)
puts aim_test
puts aim_test[0] * aim_test[1]

puts "part 2"
aim = part2_reduce(movements)
puts aim
puts aim[0] * aim[1]