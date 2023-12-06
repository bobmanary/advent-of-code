require 'set'
require 'fiber'

numbers = File.read('inputs/01.txt').lines.map(&:to_i).to_set

def find_numbers(numbers, sum)
  found_pairs = []
  numbers.each do |n|
    n2 = sum - n
    puts "#{n} + #{n2} == 2020: #{numbers.include?(n2) ? 'FOUND' : 'not found'}"
    if numbers.include?(n2)
      found_pairs << [n, n2]
    end
  end
  found_pairs
end

def find_three_operands(numbers, sum = 2020)
  numbers.each do |n|
    expected_result = sum - n
    numbers.each do |n2|
      er2 = expected_result - n2
      if numbers.include?(er2)
        return [n, n2, er2]
      end
    end
  end
  return
end

pairs = find_numbers(numbers, 2020)

puts pairs[0][0] * pairs[0][1]
# 935419

puts find_three_operands(numbers).reduce(1, &:*)