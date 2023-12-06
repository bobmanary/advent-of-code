NUMERIC_WORD_MAP = {
  "zero" => "0",
  "one" => "1",
  "two" => "2",
  "three" => "3",
  "four" => "4",
  "five" => "5",
  "six" => "6",
  "seven" => "7",
  "eight" => "8",
  "nine" => "9",
  "0" => "0",
  "1" => "1",
  "2" => "2",
  "3" => "3",
  "4" => "4",
  "5" => "5",
  "6" => "6",
  "7" => "7",
  "8" => "8",
  "9" => "9"
}

def parse(lines)
  numbers = lines.map do |line|
    chars = Char::Reader.new(line)
    numeric_chars = chars.select do |char|
      char >= '0' && char <= '9'
    end.to_a
    raise "oh no" if numeric_chars.empty?
    (numeric_chars.first + numeric_chars.last.to_s).to_i
  end
  numbers
end

def each_char_index(string, &block)
  string.chars.size.times do |i|
    yield(i, string)
  end
end

def parse_line2(line)
  results = [] of String
  each_char_index(line) do |i, string|
    match = string[i, 5].match(/^(zero|one|two|three|four|five|six|seven|eight|nine|0|1|2|3|4|5|6|7|8|9)/)
    if match
      results << match[0]
    end
  end
  raise "oh no" if results.empty?
  NUMERIC_WORD_MAP[results.first] + NUMERIC_WORD_MAP[results.last]
end

def parse2(lines)
  lines.map do |line|
    parse_line2(line).to_i
  end
end



puts parse("1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet".lines).sum

puts parse(File.read("inputs/01.txt").lines).sum


test2 = "two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen"

puts parse2(test2.lines).sum

puts parse2(File.read("inputs/01.txt").lines).sum
