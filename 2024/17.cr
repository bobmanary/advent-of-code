require "benchmark"
[
  # "inputs/17_test1.txt",
  # "inputs/17_test2.txt",
  "inputs/17.txt"
].each do |filename|
  computer = parse(filename)
  p1 = [] of Int32
  # Benchmark.ips do |bm|
  #   bm.report { computer.reset; p1 = part1(computer) }
  # end
  p1 = part1(computer)
  puts "#{filename} part 1: #{p1.join(',')}"
  p2 = part2(computer)
  puts "#{filename} part 2: #{p2}"
end

def parse(filename)
  matches = File.read(filename).match(/Register A: (\d+)\nRegister B: (\d+)\nRegister C: (\d+)\n\nProgram: ([\d,]+)/)
  raise "could not parse read #{filename}" if matches.nil?
  Computer.new(
    matches[1].to_i64,
    matches[2].to_i64,
    matches[3].to_i64,
    matches[4].split(',').map(&.to_u8)
  )
end

def part1(computer)
  computer.execute
  computer.output
end

def part2(computer)
  # puts "expected #{computer.program}"
  last_output_size = 0
  last_output_digit = 0
  last_output = [] of Int64
  since_last_digit_change = Array(Int64).new(16, 0)
  change_count_digit1 = 0
  since_change1 = 0
  since_change2 = 0
  since_change3 = 0
  0.upto(1300000) do |reg_value|
    computer.reset
    computer.set_register_a(reg_value)
    computer.execute
    # puts "#{reg_value} #{computer.output}"
    output = computer.output
    i = 0
    output.reverse_each do |digit|

    end
    since_change1 += 1
    since_change2 += 1
    since_change3 += 1
    if computer.output.size > last_output.size
      puts "output size increased at #{reg_value} to #{computer.output}"
    end
    if last_output.size > 0 && last_output.last != computer.output.last
      change_count_digit1 += 1
      puts "  last digit changed from #{last_output_digit} to #{computer.output.last} at #{reg_value} (#{since_change1} since previous change, #{change_count_digit1} total changes"
      since_change1 = 0
    end
    if last_output.size > 1 && last_output[-2] != computer.output[-2]
      puts " second last digit changed from #{last_output[-2]} to #{computer.output[-2]} at #{reg_value} (#{since_change2} since previous change)"
      since_change2 = 0
    end
    if last_output.size > 2 && last_output[-3] != computer.output[-3]
      puts "third last digit changed from #{last_output[-3]} to #{computer.output[-3]} at #{reg_value} (#{since_change3} since previous change)"
      since_change3 = 0
    end
    last_output = computer.output.dup
  end
  puts "--"
  last_output_size = 0
  reg_value = 0i64
  values = Array(Int64).new(16, 0)
  0.upto(45).step(3).each do |i|
    puts i
    reg_value = 1i64 << i
    computer.reset
    computer.set_register_a(reg_value)
    computer.execute
    if computer.output.size > last_output_size
      puts "output size increased at #{i} iterations (#{reg_value}) to #{computer.output} (#{computer.output.size}/#{computer.program.size})"
      last_output_size = computer.output.size
    end
  end

  reg_value = (reg_value << 3) - 1
  computer.reset
  computer.set_register_a(reg_value)
  computer.execute
  puts "#{computer.output} (#{computer.output.size})  #{reg_value}"
  # while reg_value < Int64::MAX
  #   reg_value = reg_value << 1
  # end

  return reg_value
  # i = 2i64
  # find_by_size = true
  # loop do
  #   # puts i if i % 100000 == 0
  #   computer.reset
  #   computer.set_register_a(i)
  #   computer.execute
  #   # puts "#{i}:"
  #   if find_by_size
  #     if computer.output.size == computer.program.size - 1
  #       find_by_size = false
  #     else
  #       i = i * 2
  #     end
  #   else
  #     puts computer.output
  #     puts computer.program
  #     if computer.output == computer.program
  #       return i
  #     else
  #       i += 1
  #     end
  #   end
  # end
  # raise "didn't find a value"
end

class Computer
  @registers : Int64[3]
  @orig_registers : Int64[3]
  getter program : Array(UInt8)
  @psize : Int32
  @ip : Int32
  getter output : Array(Int64)

  def initialize(reg_a, reg_b, reg_c, @program : Array(UInt8))
    @psize = @program.size
    @registers = StaticArray[reg_a, reg_b, reg_c]
    @orig_registers = StaticArray[reg_a, reg_b, reg_c]
    @ip = 0
    @output = [] of Int64
  end

  def set_register_a(val)
    @registers[0] = val
  end

  def reset
    @output = [] of Int64
    @ip = 0
    @registers = @orig_registers.dup
  end

  def print_state
    puts <<-STATE
    ip: #{@ip}
    registers: #{@registers[0]}
               #{@registers[1]}
               #{@registers[2]}
    output: #{@output}
    STATE
  end

  def execute()
    while @ip < @psize
      case opcode
      when 0 then i_adv
      when 1 then i_bxl
      when 2 then i_bst
      when 3 then i_jnz
      when 4 then i_bxc
      when 5 then i_out
      when 6 then i_bdv
      when 7 then i_cdv
      else
        raise "bad instruction #{opcode}"
      end
    end
  end

  def opcode
    @program[@ip]
  end

  def combo_operand : Int64
    value = @program[@ip+1]

    return case
    when value <= 3
      value.to_i64
    when value == 4
      @registers[0]
    when value == 5
      @registers[1]
    when value == 6
      @registers[3]
    else
      raise "bad operand #{value}"
    end
  end

  def literal_operand : Int64
    @program[@ip+1].to_i64
  end

  def i_adv # 0
    a = @registers[0]
    denominator = 2 ** combo_operand
    @registers[0] = a // denominator
    @ip += 2
  end

  def i_bxl # 1
    @registers[1] = @registers[1] ^ literal_operand
    @ip += 2
  end

  def i_bst # 2
    @registers[1] = combo_operand % 8
    @ip += 2
  end

  def i_jnz # 3
    if @registers[0] == 0
      @ip += 2
    else
      @ip = literal_operand.to_i32
    end
  end

  def i_bxc # 4
    @registers[1] = @registers[1] ^ @registers[2]
    @ip += 2
  end

  def i_out # 5
    @output << combo_operand % 8
    @ip += 2
  end

  def i_bdv # 6
    @registers[1] = @registers[0] // (2 ** combo_operand)
    @ip += 2
  end

  def i_cdv # 7
    @registers[2] = @registers[0] // (2 ** combo_operand)
    @ip += 2
  end
end
