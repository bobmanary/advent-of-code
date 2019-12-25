require_relative 'lib/intcode_computer.rb'

if ARGV[0] == '--test'
  day7_part1 = [0,1,2,3,4].permutation.map do |phases|
    puts "new phase #{phases.join ' '}" if DEBUG
    phases.reduce(0) do |output, phase|
      comp = IntcodeComputer.new(load_program('inputs/2019-07.txt'))
      comp.add_inputs([phase, output])
      while comp.run
        puts "- STATE #{comp.state}" if DEBUG
      end
      comp.consume_output
    end
  end.max
  if day7_part1 != 880726
    puts "day 7 test: failed" 
    exit
  else
    puts "day 7 test: passed"
  end

  -> do
    initial_program = [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99]
    output = []
    comp = IntcodeComputer.new initial_program
    while comp.run
      if comp.state == IntcodeComputer::State::WAIT_OUTPUT
        output << comp.consume_output
      end
    end
    puts "day 9 test 1: #{initial_program == output}"
    if initial_program != output
      max_len = [initial_program.size, output.size].max
      puts "largest set: #{max_len}"
      max_len.times do |i|
        puts "#{initial_program[i]} | #{output[i]}"
      end
    end
  end.call

  -> do
    initial_program = [1102,34915192,34915192,7,4,7,99,0]
    output = []
    comp = IntcodeComputer.new initial_program
    while comp.run
      if comp.state == IntcodeComputer::State::WAIT_OUTPUT
        output << comp.consume_output
      end
    end
    puts "day 9 test 2: #{output.size == 1}, #{output[0].to_s.size == 16}"
  end.call


  -> do
    initial_program = [104,1125899906842624,99]
    output = []
    comp = IntcodeComputer.new initial_program
    while comp.run
      if comp.state == IntcodeComputer::State::WAIT_OUTPUT
        output << comp.consume_output
      end
    end
    puts "day 9 test 3: #{output.size == 1}, #{output[0] == 1125899906842624}"
  end.call
end

# day 9 part 1
-> do
  comp = IntcodeComputer.new(load_program('inputs/09.txt'))
  outputs = []
  comp.add_inputs [1]
  while comp.run
    puts 'continue'
    if comp.wait_output?
      outputs << comp.consume_output
      puts "consume output, now: #{outputs.join(',')}"
    end
  end
  puts "final state: #{comp.state}"
  puts "day 9 part 1: #{outputs}"
end.call