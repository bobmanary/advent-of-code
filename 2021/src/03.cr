require "bit_array"
# input_test_1 = "00100
# 11110
# 10110
# 10111
# 10101
# 01111
# 00111
# 11100
# 10000
# 11001
# 00010
# 01010"

def convert(str) : Array(BitArray)
  width = str.lines.first.size
  str.lines.map do |line|
    bits = BitArray.new(width)
    line.each_char_with_index do |char, i|
      bits[i] = char == '0' ? false : true
    end
    bits
  end
end

def rotate(input) : Array(BitArray)
  rotated = [] of BitArray
  input.first.size.times do rotated.push(BitArray.new(input.size)) end

  input.each_with_index do |bits, i|
    bits.each_with_index do |bit, j|
      rotated[j][i] = bit
    end
  end
  rotated
end

def calc_most_common(input : Array(BitArray)) : BitArray
  output = BitArray.new(input.size)

  input.each_with_index do |bits, i|
    zeroes = 0
    ones = 0
    bits.each do |bit|
      if bit
        ones += 1
      else
        zeroes += 1
      end
    end
    output[i] = zeroes > ones ? false : true
  end

  output
end

def bitarray_to_int(bits : BitArray) : UInt32
  int = UInt32.new(0)
  bits.reverse!.each_with_index do |bit, i|
    int = int ^ ((bit ? 1 : 0) << i)
  end
  int
end

def calculate_diagnostic(gamma_rate : BitArray) : UInt32
  epsilon_rate = gamma_rate.dup
  epsilon_rate.toggle(0..)
  bitarray_to_int(gamma_rate) * bitarray_to_int(epsilon_rate)
end

# puts convert(input_test_1)
# puts rotate(convert(input_test_1))
# puts calc_most_common(rotate(convert(input_test_1)))
# puts calculate_diagnostic calc_most_common(rotate(convert(input_test_1)))

input = File.read("inputs/03.txt").lines.sort.to_s
puts calculate_diagnostic calc_most_common(rotate(convert(input)))
