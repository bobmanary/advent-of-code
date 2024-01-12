require "benchmark"

def parse(filename)
  File.read(filename).chomp.chars
end

def part1(input)
  hash(input)
end

def hash(chars)
  sum = 0
  current = 0
  chars.each do |char|
    if char == ','
      sum += current
      current = 0
      next
    end

    current += char.ord
    current *= 17
    current %= 256
  end
  sum + current
end

def part2(input)
  boxes = Array(Array({String, UInt8})).new(256) { [] of {String, UInt8}}
  label = [] of Char
  current = 0

  input.each_with_index do |char, i|
    next if char.ascii_number? || char == ','
    if char == '-'

      box = boxes[current]
      label_str = label.join
      idx = box.index {|lens| lens[0] == label_str}
      if !idx.nil?
        box.delete_at(idx)
      end
      current = 0
      label.clear
    elsif char == '='
      box = boxes[current]
      lens_number = input[i+1].to_u8
      label_str = label.join
      idx = box.index {|lens| lens[0] == label_str}
      if idx.nil?
        box << {label_str, lens_number}
      else
        box[idx] = {label_str, lens_number}
      end
      current = 0
      label.clear
    else
      current += char.ord
      current *= 17
      current %= 256
      label << char
    end
  end

  boxes.each_with_index.reduce(0) do |acc, (box, box_number)|
    next acc if box.empty?
    acc + box.each_with_index.reduce(0) do |acc2, ((label, focal_length), slot_number)|
      acc2 + ((1 + box_number) * (1 + slot_number) * focal_length)
    end
  end
end

Benchmark.ips do |x|
  ["inputs/15_example.txt", "inputs/15.txt"].each do |filename|
    input = parse(filename)

    x.report("#{filename} part 1") do
      part1(input)
    end

    x.report("#{filename} part 2") do
      part2(input)
    end
  end
end