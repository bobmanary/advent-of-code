#!/usr/bin/env ruby
require 'benchmark'
puts (Benchmark.measure do
range = Range.new(*"284639-748759".split('-').map(&:to_i))
puts range

def never_decreases(digits)
  digits[0] <= digits[1] &&
  digits[1] <= digits[2] &&
  digits[2] <= digits[3] &&
  digits[3] <= digits[4] &&
  digits[4] <= digits[5]
end

def has_doubles(digits)
  digits[0] == digits[1] ||
  digits[1] == digits[2] ||
  digits[2] == digits[3] ||
  digits[3] == digits[4] ||
  digits[4] == digits[5]
end

def has_strict_doubles(digits)
  return false if !has_doubles(digits)
  digits.each_with_object([]) do |digit, memo|
    if memo.last.nil? || memo.last.last != digit
      memo << [digit]
    else
      memo.last << digit
    end
  end.find { |group| group.size == 2 } != nil
end

def int_to_digits(i)
  [
    i / 100000,
    i / 10000 - i / 100000 * 10,
    i / 1000 - i / 10000 * 10,
    i / 100 - i / 1000*10,
    i / 10 - i/100*10,
    i - i/10*10,
  ]
end


matching_passwords = range.select do |i|
  digits = int_to_digits(i)
  never_decreases(digits) && has_doubles(digits)
end

def assert(test, msg)
  raise "failed test #{msg}" if !test
end

assert never_decreases([1,1,1,1,1,1]), '1'
assert has_doubles([1,1,1,1,1,1]), '2'
assert !never_decreases([2,2,3,4,5,0]), '3'
assert has_doubles([2,2,3,4,5,0]), '4'
assert never_decreases([1,2,3,7,8,9]), '5'
assert !has_doubles([1,2,3,7,8,9]), '6'

puts "part 1: #{matching_passwords.size} found"

matching_passwords2 = range.select do |i|
  digits = int_to_digits(i)
  never_decreases(digits) && has_strict_doubles(digits)
end

puts "part 2: #{matching_passwords2.size}"
end)