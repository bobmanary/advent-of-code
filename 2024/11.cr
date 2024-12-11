require "benchmark"

[
  {"inputs/11_test1.txt", 1},
  {"inputs/11_test2.txt", 6},
  {"inputs/11_test2.txt", 25},
  {"inputs/11.txt", 25},
  {"inputs/11.txt", 75},
].each do |(filename, blinks)|
  result = 0u64
  Benchmark.ips do |bm|
    bm.report("#{filename}, #{blinks} blinks:") do
      stones = parse(filename)
      result = count_stones(stones, blinks)
    end
  end
  puts "result: #{result}"
end

def parse(filename)
  File.read(filename).split.map {|num| {num.to_i64, num}}
end

def count_stones(stones, blinks)
  count = 0i64
  memo = Hash({Int64, Int32}, UInt64).new
  stones.each_with_index do |stone, i|
    count += apply_rules(stone, blinks, memo)
  end

  count
end

def apply_rules(stone : {Int64, String}, blinks_remaining, memo) : UInt64
  return 1u64 if blinks_remaining == 0

  blinks_remaining -= 1
  if memo.has_key?({stone[0], blinks_remaining})
    return memo[{stone[0], blinks_remaining}]
  end
  count = 0u64

  if stone[0] == 0
    count += apply_rules({1i64, "1"}, blinks_remaining, memo)
  elsif stone[1].size.even?
    string_halves(stone[1]) do |new_str|
      count += apply_rules({new_str.to_i64, new_str.to_i64.to_s}, blinks_remaining, memo)
    end
  else
    new_num = stone[0] * 2024
    count += apply_rules({new_num, new_num.to_s}, blinks_remaining, memo)
  end

  memo[{stone[0], blinks_remaining}] = count
  count
end

def string_halves(str)
  yield str.byte_slice(0, str.size // 2)
  yield str.byte_slice(str.size // 2)
end
