#
["inputs/03_test.txt", "inputs/03_test2.txt", "inputs/03.txt"].each do |filename|
  file = File.read(filename)
  program = parse(file)
  puts "#{filename} part 1: #{part1(program)}"
  puts "#{filename} part 2: #{part2(program)}"
end

enum Instruction
  DO
  DONT
  MUL
end

def parse(program : String)
  arguments = [] of {Instruction, Int32, Int32}
  program.scan(/(mul|do|don't)\(((\d+),(\d+))?\)/) do |result|
    instruction = case result[1]
    when "do" then Instruction::DO
    when "don't" then Instruction::DONT
    when "mul" then Instruction::MUL
    else raise "oops"
    end
    if instruction == Instruction::MUL
      a = result[3].to_i
      b = result[4].to_i
    else
      a = 0
      b = 0
    end
    arguments << {instruction, a, b}
  end
  arguments
end

def part1(program : Array({Instruction, Int32, Int32}))
  program.reduce(0) do |acc, (instruction, a, b)|
    next acc if instruction != Instruction::MUL
    acc + (a * b)
  end
end

def part2(program : Array({Instruction, Int32, Int32}))
  should_multiply = true
  program.reduce(0) do |acc, (instruction, a, b)|
    case instruction
    when Instruction::DO
      should_multiply = true
      next acc
    when Instruction::DONT
      should_multiply = false
      next acc
    when Instruction::MUL
      next acc unless should_multiply
      acc + (a * b)
    else
      raise "invalid instruction #{instruction}"
    end
  end
end
