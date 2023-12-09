def parse_card_wins(line) : Int32
  winning_numbers = [] of Int32
  own_numbers = [] of Int32
  is_parsing_winners = true
  line.split do |item|
    if item == "|"
      is_parsing_winners = false
      next 
    end
    (is_parsing_winners ? winning_numbers : own_numbers) << item.to_i
  end
  (winning_numbers & own_numbers).size
end

["inputs/04_example.txt", "inputs/04.txt"].each do |filename|
  result = File.read(filename).each_line.reduce(0) do |acc, line|
    wins = parse_card_wins(line.partition(": ")[2])
    w = if wins > 1
      (wins - 1).times.reduce(1) { |acc, x| acc * 2 }
    else
      wins
    end
    acc + w
  end
  puts "part 1 #{filename}: #{result}"
end

["inputs/04_example.txt", "inputs/04.txt"].each do |filename|
  cards = File.read(filename)
  initial_card_count = cards.lines.size
  running_card_counts = Hash(Int32, UInt64).new(1, initial_card_count)

  cards.each_line do |line|
    line.match(/Card\s+(\d+): ([\s\d|]+)/)
    current_card_number = $~[1].to_i

    running_card_counts.put_if_absent(current_card_number, 1)
    current_card_count = running_card_counts[current_card_number]

    win_count = parse_card_wins($~[2])

    win_count.times do |j|
      next_card_index = current_card_number + j + 1
      if next_card_index <= initial_card_count
        running_card_counts[next_card_index] = running_card_counts[next_card_index] + current_card_count
      end
    end
  end


  result = running_card_counts.values.sum
  puts "part 2 #{filename}: #{result}"
end