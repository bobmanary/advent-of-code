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

  extra_tests = [
    {in: [], out: [-1], prog: [109, -1, 4, 1, 99]},
    {in: [], out: [1], prog: [109, -1, 104, 1, 99]},
    {in: [], out: [109], prog: [109, -1, 204, 1, 99]},
    {in: [], out: [204], prog: [109, 1, 9, 2, 204, -6, 99]},
    {in: [], out: [204], prog: [109, 1, 109, 9, 204, -6, 99]},
    {in: [], out: [204], prog: [109, 1, 209, -1, 204, -106, 99]},
    {in: [999], out: [999], prog: [109, 1, 3, 3, 204, 2, 99]},
    {in: [11], out: [11], prog: [109, 1, 203, 2, 204, 2, 99]},
  ]
  extra_tests.each_with_index do |test, i|
    puts "> program ##{i}: [#{test[:prog].join(', ')}]"
    comp = IntcodeComputer.new test[:prog]
    comp.add_inputs test[:in]
    outputs = []
    while comp.run
      if comp.state == IntcodeComputer::State::WAIT_OUTPUT
        outputs << comp.consume_output
      end
    end
    puts "extra test #{i}: #{test[:out].eql?(outputs) ? 'pass' : 'fail'}"
    puts "output: [#{outputs.join(',')}]"
    puts "============================" if DEBUG
  end
end

# day 9 part 1
if !ARGV.include?('--test')
  -> do
    comp = IntcodeComputer.new(load_program('inputs/09.txt'))
    outputs = []
    comp.add_inputs [1]
    while comp.run
      if comp.wait_output?
        outputs << comp.consume_output
      end
    end
    puts "day 9 part 1: #{outputs}"
  end.call
end