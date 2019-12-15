require 'fiber'

DEBUG=false
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

def load_program
  File.read('inputs/2019-07.txt').split(',').map &:to_i
end

class IntcodeComputer
  module State
    HALTED = 0
    INIT = 1
    RUNNING = 2
    WAIT_INPUT = 3
    WAIT_OUTPUT = 4
  end
  
  attr_accessor :program, :ip, :jump_pointer, :output, :halted, :opcodes, :loaders, :state

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
      @program[@ip + ip_offset]
    elsif mode == 1
      # immediate mode
      @ip + ip_offset
    elsif mode == 2
      # relative mode
      relative_offset = @program[@ip + ip_offset]
      @rel_base + relative_offset
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
end



# part 1
part1 = [0,1,2,3,4].permutation.map do |phases|
  puts "new phase #{phases.join ' '}" if DEBUG
  phases.reduce(0) do |output, phase|
    comp = IntcodeComputer.new(load_program)
    comp.add_inputs([phase, output])
    while comp.run
      puts "- STATE #{comp.state}" if DEBUG
    end
    comp.output
    # IntcodeComputer.new(load_program).run([phase, output])
  end
end.max
raise "oh noes" if part1 != 880726
puts "part 1: #{part1}"
