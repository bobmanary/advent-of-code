DEBUG=false
PRINT_STATE=false

def decode(instruction)
  instruction_str = instruction.to_s.rjust(5, '0')

  opcode = instruction_str[-2..-1].to_i
  m1 = instruction_str[-3].to_i
  m2 = instruction_str[-4].to_i
  m3 = instruction_str[-5].to_i

  size = case opcode
  when 1, 2,7,8
    4
  when 5,6
    3
  when 3,4
    2
  when 99
    1
  else
    raise "invalid instruction #{instruction_str}"
  end
  [opcode, [m1, m2, m3], size]
end

def load_program
  cmds = File.read('inputs/05.txt').split(',').map &:to_i
  puts "program size: #{cmds.size}"
  cmds
end

def load_arguments(program, ip, param_modes, instr_size)
  param_count = instr_size - 1
  param_start = ip + 1

  params = program.slice(param_start, param_count).map.with_index do |val, i|
    puts "-- #{i} #{val} #{instr_size}" if DEBUG
    if i+2 == instr_size || param_modes[i] == 1
      puts '-- a' if DEBUG
      val.to_i
    else
      puts '-- b' if DEBUG
      program[val.to_i].to_i
    end
    # param_modes[i] == 0 ? program[val.to_i].to_i : val.to_i
  end
end

def run(program, input)
  ip = 0
  jump_pointer = 0
  output = nil
  halted = false
  opcodes = {
    1 => -> (p1, p2, p3) { program[p3] = p1 + p2 },
    2 => -> (p1, p2, p3) { program[p3] = p1 * p2 },
    3 => -> (p1) { program[p1] = input },
    4 => -> (p1) { puts '!'; output = p1 },
    5 => -> (p1, p2) { puts "> JT #{p2}" if p1 != 0; jump_pointer = p2 if p1 != 0 },
    6 => -> (p1, p2) { puts "> JF #{p2}" if p1 == 0; jump_pointer = p2 if p1 == 0 },
    7 => -> (p1, p2, p3) { program[p3] = p1 < p2 ? 1 : 0},
    8 => -> (p1, p2, p3) { program[p3] = p1 == p2 ? 1 : 0},
    99 => -> { halted = true }
  }
  loaders = {
    1 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1], modes[1] == 0 ? program[program[ip+2]] : program[ip+2], program[ip+3]]},
    2 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1], modes[1] == 0 ? program[program[ip+2]] : program[ip+2], program[ip+3]]},
    3 => -> (modes) {[program[ip+1]]},
    4 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1]]},
    5 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1], modes[1] == 0 ? program[program[ip+2]] : program[ip+2]]},
    6 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1], modes[1] == 0 ? program[program[ip+2]] : program[ip+2]]},
    7 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1], modes[1] == 0 ? program[program[ip+2]] : program[ip+2], program[ip+3]]},
    8 => -> (modes) {[modes[0] == 0 ? program[program[ip+1]] : program[ip+1], modes[1] == 0 ? program[program[ip+2]] : program[ip+2], program[ip+3]]},
    99 => -> (modes) {[]}
  }
  if DEBUG
    def program.[]=(index, value)
      puts "WROTE [#{index}] = #{value}"
      super(index, value)
    end
    def program.[](index)
      puts "READ  [#{index}] = #{super(index)}"
      super(index)
    end
  end

  while !halted
    begin
      if !jump_pointer.nil?
        ip = jump_pointer
        jump_pointer = nil
      end
      (opcode, param_modes, instr_size) = decode(program[ip])
      arguments = loaders[opcode].call(param_modes)
      puts "ip #{ip.to_s.rjust(3, '0')}, cmd #{program.at(ip).to_s.rjust(5, ' ')}, opcode #{opcode}, size #{instr_size}, mode #{param_modes.join(',')}, values #{arguments.join(',')}" if DEBUG
      # arguments = load_arguments(program, ip, param_modes, instr_size)
      opcodes[opcode].call(*arguments)
      ip += instr_size
      if PRINT_STATE
        puts program.map {|v| v.to_s.rjust(5, '0')}.join(', ')
        sleep(0.1)
      end
    rescue StandardError => e
      puts "error at ip #{ip}, #{program[ip]} (program size: #{program.size})"
      raise e
    end
  end
  output
end

# puts run(load_program, 1) # part 1
puts run load_program, 5 # part 2
# puts run [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
#   1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
#   999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99
#   ], 1