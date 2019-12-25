require 'fiber'

DEBUG=!ENV['DEBUG'].nil?
PRINT_STATE=false

def decode(instruction)
  instruction_str = instruction.to_s.rjust(5, '0')

  opcode = instruction_str[-2..-1].to_i
  m1 = instruction_str[-3].to_i
  m2 = instruction_str[-4].to_i
  m3 = instruction_str[-5].to_i

  size = case opcode
  when 1,2,7,8
    4
  when 5,6
    3
  when 3,4,9
    2
  when 99
    1
  else
    raise "invalid instruction #{instruction_str}"
  end
  [opcode, [m1, m2, m3], size]
end

def load_program(path)
  File.read(path).split(',').map &:to_i
end

class IntcodeComputer
  module State
    HALTED = 0
    INIT = 1
    RUNNING = 2
    WAIT_INPUT = 3
    WAIT_OUTPUT = 4
  end
  
  attr_accessor :program, :ip, :jump_pointer, :halted, :opcodes, :loaders, :state

  def initialize(new_program)
    @program = new_program.clone

    @inputs = []
    @state = State::INIT
    @ip = 0
    @jump_pointer = 0
    @output = nil
    @halted = false
    @rel_base = 0
    @opcodes = {
      1 => -> (p1, p2, p3) { @program[p3] = p1 + p2 },
      2 => -> (p1, p2, p3) { @program[p3] = p1 * p2 },
      3 => -> (p1) { @program[p1] = get_input },
      4 => -> (p1) { set_output(p1) },
      5 => -> (p1, p2) { puts "> JT #{p2}" if p1 != 0 && DEBUG; @jump_pointer = p2 if p1 != 0 },
      6 => -> (p1, p2) { puts "> JF #{p2}" if p1 == 0 && DEBUG; @jump_pointer = p2 if p1 == 0 },
      7 => -> (p1, p2, p3) { @program[p3] = p1 < p2 ? 1 : 0},
      8 => -> (p1, p2, p3) { @program[p3] = p1 == p2 ? 1 : 0},
      9 => -> (p1) { @rel_base += p1 },
      99 => -> { @state = State::HALTED }
    }
    @loaders = {
      1 => -> (modes) {[load_arg(modes[0], 1), load_arg(modes[1], 2), load_arg(1, 3)]},
      2 => -> (modes) {[load_arg(modes[0], 1), load_arg(modes[1], 2), load_arg(1, 3)]},
      3 => -> (modes) {[load_arg(1, 1)]},
      4 => -> (modes) {[load_arg(modes[0], 1)]},
      5 => -> (modes) {[load_arg(modes[0], 1), load_arg(modes[1], 2)]},
      6 => -> (modes) {[load_arg(modes[0], 1), load_arg(modes[1], 2)]},
      7 => -> (modes) {[load_arg(modes[0], 1), load_arg(modes[1], 2), load_arg(1, 3)]},
      8 => -> (modes) {[load_arg(modes[0], 1), load_arg(modes[1], 2), load_arg(1, 3)]},
      9 => -> (modes) {[load_arg(modes[0], 1)]},
      99 => -> (modes) {[]}
    }

    if DEBUG
      def @program.[]=(index, value)
        puts "WROTE [#{index}] = #{value}"
        super(index, value)
      end
      def @program.[](index)
        puts "READ  [#{index}] = #{super(index)}"
        super(index)
      end
    end
    start_fiber.resume
  end

  private
  def load_arg(mode, ip_offset)
    address = if mode == 0
      # position mode
      load_arg(1, ip_offset)
    elsif mode == 1
      # immediate mode
      @ip + ip_offset
    elsif mode == 2
      # relative mode
      relative_offset = load_arg(1, ip_offset)
      @rel_base + relative_offset
    end
    if address > @program.size
      puts "EXPANDING MEMORY TO #{address}"
      @program.fill 0, @program.size, (address+1) - @program.size
      puts "... #{@program.size}"
      puts "#{@program[address]}"
    end
    @program[address]
  end

  def get_input
    val = @inputs.shift
    puts "READ INPUT #{val.nil? ? 'nil, suspending' : val}" if DEBUG
    if val.nil?
      @state = State::WAIT_INPUT
      if @fiber == Fiber.current
        puts 'waiting on input?'
        Fiber.yield
      else
        raise "wtf wrong fiber?"
      end
      # raise 'no input' if val.nil?
      nil
    else
      val
    end
  end

  def set_output(val)
    @state = State::WAIT_OUTPUT
    @output = val
    puts "SET OUTPUT #{val}" if DEBUG
    Fiber.yield
    nil
  end

  def start_fiber
    @fiber = Fiber.new do
      Fiber.yield
      @state = State::RUNNING
      while @state != State::HALTED
        begin
          if !@jump_pointer.nil?
            @ip = @jump_pointer
            @jump_pointer = nil
          end
          (opcode, param_modes, instr_size) = decode(@program[@ip])
          # arguments = load_args(opcode, instr_size, param_modes)
          arguments = @loaders[opcode].call(param_modes)
          puts "ip #{@ip.to_s.rjust(3, '0')}, cmd #{@program.at(@ip).to_s.rjust(5, ' ')}, opcode #{opcode}, size #{instr_size}, mode #{param_modes.join(',')}, values #{arguments.join(',')}" if DEBUG
          @opcodes[opcode].call(*arguments)
          @ip += instr_size
          if PRINT_STATE
            puts @program.map {|v| v.to_s.rjust(5, '0')}.join(', ')
            sleep(0.1)
          end
        rescue StandardError => e
          puts "error at ip #{@ip}, #{@program[@ip]} (program size: #{@program.size})"
          puts @program.join(',')
          raise e
        end
      end
    end
  end

  public  
  def add_inputs(inputs = [])
    # raise 'wrong state for setting input' unless [State::INIT, State::WAIT_INPUT].include? @state
    @inputs.push *inputs
  end
  
  def run
    if @state == State::HALTED
      false
    else
      @fiber.resume
      true
    end
  end

  def stopped?
    @state == State::HALTED
  end

  def wait_output?
    @state == State::WAIT_OUTPUT
  end

  def consume_output
    puts "consume_output #{@output}, state: #{@state}" if DEBUG
    raise "Bad consume_output" if !wait_output? && !stopped?
    out = @output
    @output = nil
    @state = State::RUNNING if !stopped?
    out
  end
end

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
    if comp.wait_output?
      outputs << comp.consume_output
    end
  end
  puts "day 9 part 1: #{outputs}"
end.call