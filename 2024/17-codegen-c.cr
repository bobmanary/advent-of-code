THREAD_COUNT = 6
[
  "inputs/17_test1.txt",
  "inputs/17_test2.txt",
  "inputs/17.txt"
].each do |filename|
  basename = File.basename(filename, ".txt")
  output_name = "17-generated-#{basename}.c"
  puts "\n\n#{output_name}"
  a, b, c, bytecode = parse(filename)
  generated_c = build_c_body(THREAD_COUNT, bytecode, translate_wide(bytecode, 8), 8)
  File.write(output_name, generated_c)
end

def combo_operand(operand)
  if operand <= 3
    operand.to_s
  elsif operand == 4
    "a"
  elsif operand == 5
    "b"
  elsif operand == 6
    "c"
  else
    raise "Unexpected combo operand #{operand}"
  end
end

def adv(operand) # opcode 0
  "      a = a % #{combo_operand(operand)};"
end

def bxl(operand) # opcode 1
  "      b = b ^ #{operand};"
end

def bst(operand) # 2
  "      b = #{combo_operand(operand)} % 8;"
end

def bxc(operand)
  "      b = b & c;"
end

def outp(operand)
  <<-C
        output[output_index] = #{combo_operand(operand)} % 8;
        output_index += 1;
  C
end

def bdv(operand)
  "      b = a >> #{combo_operand(operand)};"
end

def cdv(operand)
  "      c = a >> #{combo_operand(operand)};"
end





def w_combo_operand(operand, n)
  if operand <= 3
    operand.to_s
  elsif operand == 4
    "a#{n}"
  elsif operand == 5
    "b#{n}"
  elsif operand == 6
    "c#{n}"
  else
    raise "Unexpected combo operand #{operand}"
  end
end

def w_adv(operand, width) # opcode 0
  String.build do |str|
    width.times do |i|
      str << "      a#{i} = a#{i} % #{w_combo_operand(operand, i)};\n"
    end
  end
end

def w_bxl(operand, width) # opcode 1
  String.build do |str|
    width.times do |i|
      puts "w_bxl #{width} #{i}"
      str << "      b#{i} = b#{i} ^ #{operand};\n"
    end
  end
end

def w_bst(operand, width) # 2
  String.build do |str|
    width.times do |i|
      str << "      b#{i} = #{w_combo_operand(operand, i)} % 8;\n"
    end
  end
end

def w_bxc(operand, width)
  String.build do |str|
    width.times do |i|
      str << "      b#{i} = b#{i} & c#{i};\n"
    end
  end
end

def w_outp(operand, width)
  String.build do |str|
    width.times do |i|
      str << "      output#{i}[output_index] = #{w_combo_operand(operand, i)} % 8;\n"
    end
    str << "      output_index += 1;\n"
  end
end

def w_bdv(operand, width)
  String.build do |str|
    width.times do |i|
      str << "      b#{i} = a#{i} >> #{w_combo_operand(operand, i)};\n"
    end
  end
end

def w_cdv(operand, width)
  String.build do |str|
    width.times do |i|
      str << "      c#{i} = a#{i} >> #{w_combo_operand(operand, i)};\n"
    end
  end
end



def translate(bytecode : Array(UInt8))
  raise "Program too short" if bytecode.size < 4
  raise "Program length not even" if !bytecode.size.even?
  raise "Last instruction was not 'jnz'" if bytecode[-2] != 3_u8
  String.build do |str|
    str << "\n    for (int output_index = 0; output_index < OUTPUT_SIZE; output_index++) {\n"
    bytecode.in_groups_of(2, reuse: true) do |(instruction, operand)|
      raise "Missing operand" if operand.nil?

      str << case instruction
        when 0 then adv(operand)
        when 1 then bxl(operand)
        when 2 then bst(operand)
        when 3
        when 4 then bxc(operand)
        when 5 then outp(operand)
        when 6 then bdv(operand)
        when 7 then cdv(operand)
      end
      str << "\n"
    end
    str << <<-C
          if (output[output_index] != goal[output_index]) {
            found = 0;
            break;
          }

    C
    str << "    }\n"
  end
end

def translate_wide(bytecode : Array(UInt8), width = 4)
  String.build do |str|
    width.times do |n|
      str << "    int64_t a#{n} = i;\n"
      str << "    int64_t b#{n} = 0x0LL;\n"
      str << "    int64_t c#{n} = 0X0LL;\n"
      str << "    int64_t output#{n}[OUTPUT_SIZE];\n"
      str << "    int found#{n};\n\n"
    end

    str << "\n    for (int output_index = 0; output_index < OUTPUT_SIZE; output_index++) {\n"
    bytecode.in_groups_of(2, reuse: true) do |(instruction, operand)|
      raise "Missing operand" if operand.nil?

      str << case instruction
        when 0 then w_adv(operand, width)
        when 1 then w_bxl(operand, width)
        when 2 then w_bst(operand, width)
        when 4 then w_bxc(operand, width)
        when 5 then w_outp(operand, width)
        when 6 then w_bdv(operand, width)
        when 7 then w_cdv(operand, width)
        else ""
      end
      str << "      // ---\n"
    end

    str << "      if (\n"
    str << (
      width.times.map do |i|
        "        (output#{i}[output_index] != goal[output_index])"
      end.join(" &&\n")
    )
    str << "\n      ) {break;}"
    str << "\n    }\n" # end of OUTPUT_SIZE loop

    # TODO: figure out which entry had the matching output
    width.times do |i|
      str << "    if (\n"
      puts "bytecocde is #{bytecode.size}"
      str << bytecode.size.times.map do |j|
        "      output#{i}[#{j}] == goal[#{j}]"
      end.join(" &&\n")
      str << "\n    ) {found = #{i}; break;}\n"
    end
  end
end

def parse(filename)
  matches = File.read(filename).match(/Register A: (\d+)\nRegister B: (\d+)\nRegister C: (\d+)\n\nProgram: ([\d,]+)/)
  raise "could not parse read #{filename}" if matches.nil?
  {
    matches[1].to_i64,
    matches[2].to_i64,
    matches[3].to_i64,
    matches[4].split(',').map(&.to_u8)
  }
end

def build_c_body(fork_count, bytecode, translated_inner_loop, loop_width)
  goal = "{#{bytecode.join(',')}}"
  template = File.read("17_codegen_template.c")
  template
    .gsub(/^\s+\/\/ ___INNER_LOOP$/m, translated_inner_loop)
    .gsub("___THREAD_COUNT", fork_count)
    .gsub("___OUTPUT_SIZE", bytecode.size)
    .gsub("___WIDTH", loop_width)
    .gsub("___GOAL", goal)
end
