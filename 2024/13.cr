require "../2023/lib/vector2d"
[
  "inputs/13_test.txt",
  "inputs/13.txt",
].each do |filename|
  machines = parse(filename)
  p1 = part1(machines)
  puts "#{filename} part 1: #{p1}"
end

alias Vec2 = Vector2d(Int64)

class ClawMachine
  getter a : Vec2
  getter b : Vec2
  getter prize : Vec2
  def initialize(@a, @b, @prize)
  end
end

def parse(filename)
  machines = [] of ClawMachine
  File.open(filename, "r") do |file|
    while group = file.gets("\n\n")
      matches = group.scan(/(Button A|Button B|Prize): X[=+](\d+), Y[=+](\d+)\n/m)
      machines << ClawMachine.new(
        Vec2.new(matches[0][2].to_i64, matches[0][3].to_i64),
        Vec2.new(matches[1][2].to_i64, matches[1][3].to_i64),
        Vec2.new(matches[2][2].to_i64, matches[2][3].to_i64)
      )
    end
  end
  machines
end

def part1(machines)
  machines.reduce(0i64) do |acc, machine|
    min_tokens = Int64::MAX
    a_presses = (machine.prize.x // machine.a.x)
    while a_presses >= 0
      b_presses = (machine.prize.x - (a_presses * machine.a.x)) // machine.b.x
      moved_to = (machine.a * a_presses) + (machine.b * b_presses)
      while moved_to.magnitude < machine.prize.magnitude * 2
        moved_to = (machine.a * a_presses) + (machine.b * b_presses)
        if moved_to == machine.prize
          tokens = a_presses * 3 + b_presses
          min_tokens = tokens if tokens < min_tokens
        end
        b_presses += 1
      end
      a_presses -= 1
    end
    acc +( min_tokens < Int64::MAX ? min_tokens : 0)
  end
end
