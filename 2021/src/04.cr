class BingoNumber
  C_RESET = "\e[1;0m"
  C_WHITE = "\e[1;35m"
  getter value : UInt8

  def initialize(@value : UInt8)
    @picked = false
  end

  def picked?
    @picked
  end

  def unpicked?
    !@picked
  end

  def pick!
    @picked = true
  end

  def to_s(io)
    if picked?
      io << C_WHITE << @value << C_RESET
    else
      io << @value
    end
  end
end

class BingoCard
  include Enumerable(BingoNumber)

  def self.from_lines(lines : Array(String))
    new(lines.map do |line|
      line.strip.split(/\s+/).map(&.strip).map { |num| BingoNumber.new(num.to_u8) }
    end)
  end

  def initialize(@rows : Array(Array(BingoNumber)))
    @columns = [] of Array(BingoNumber)
    @completed = false

    # convert to column-based array for easier(?) checking later
    (0..4).each do |i|
      @columns << [] of BingoNumber
      (0..4).each do |j|
        @columns[i] << @rows[j][i]
      end
    end
  end

  def bingo?
    puts self
    winning_row = @rows.find do |line|
      !line.any? do |cell| cell.unpicked? end
    end
    if winning_row
      @completed = true
      return winning_row
    end

    winning_column = @columns.find do |line|
      !line.any? do |cell| cell.unpicked? end
    end
    if winning_column
      @completed = true
      return true
    end

    false
  end

  def check(number : UInt8)
    @rows.each do |row|
      row.each do |card_number|
        if number == card_number.value
          card_number.pick!
          break
        end
      end
    end
  end

  def to_s(io)
    arr = @rows
    arr.each do |line|
      line.each do |card_number|
        if card_number.value <= 9
          io << "  " << card_number
        else
          io << " " << card_number
        end
      end
      io << "\n"
    end
  end

  def each
    @rows.each do |row|
      row.each do |cell|
        yield cell
      end
    end
  end

  def completed?
    @completed
  end
end

class BingoParser
  getter numbers : Array(UInt8)
  getter cards : Array(BingoCard)

  def initialize(@lines : Array(String))
    @cards = [] of BingoCard
    @numbers = @lines.shift.split(',').map(&.to_u8)

    @lines.each_slice(6) do |slice|
      @cards << BingoCard.from_lines(slice[1..])
    end
  end
end

class BingoGame
  C_RESET = "\e[1;0m"
  C_RED = "\e[1;31m"

  getter numbers : Array(UInt8)
  getter cards : Array(BingoCard)

  def initialize(@parser : BingoParser)
    @numbers = @parser.numbers
    @cards = @parser.cards
    @numbers_called = 0
  end

  def play_round : {UInt8?, BingoCard?}
    chosen_number = @numbers.shift
    winning_cards = [] of BingoCard

    puts "#{C_RED}called #{chosen_number}#{C_RESET}"
    @cards.each do |card|
      card.check(chosen_number)
      if card.bingo?
        winning_cards << card
      end
    end
    
    if !winning_cards.empty?
      winning_cards.each do |card|
        @cards.delete(card)
      end
      return {chosen_number, winning_cards.first}
    end
    {nil, nil}
  end

  def play_game
    numbers.size.times do |i|
      winning_number, winning_card = play_round
      if winning_number && winning_card
        puts winning_card
    
        unmarked_sum = winning_card.reduce(0_u32) do |acc, cell|
          acc + (cell.picked? ? 0 : cell.value)
        end
        final_score : UInt32 = unmarked_sum * winning_number
        puts "unmarked sum: #{unmarked_sum} * #{winning_number} = #{final_score}"
        break
      end
    end
  end

  def play_game_part2
    last_card : BingoCard? = nil
    last_winning_number : Nil | UInt8 = nil

    numbers.size.times do |i|
      winning_number, winning_card = play_round
      if winning_number && winning_card
        puts "winner:"
        puts winning_card
        last_card = winning_card
        last_winning_number = winning_number
      end
    end

    if last_card && last_winning_number
      puts last_card
      unmarked_sum = last_card.reduce(0_u32) do |acc, cell|
        acc + (cell.picked? ? 0 : cell.value)
      end
      final_score : UInt32 = unmarked_sum * last_winning_number
      puts "unmarked sum: #{unmarked_sum} * #{last_winning_number} = #{final_score}"
    else
      puts "no winner?"
    end
  end
end

# test_game = BingoGame.new(BingoParser.new(File.read("inputs/04_test.txt").lines))
# test_game.play_game

# real_game = BingoGame.new(BingoParser.new(File.read("inputs/04.txt").lines))
# real_game.play_game

puts "---"

# test_game = BingoGame.new(BingoParser.new(File.read("inputs/04_test.txt").lines))
# test_game.play_game_part2

real_game_part2 = BingoGame.new(BingoParser.new(File.read("inputs/04.txt").lines))
real_game_part2.play_game_part2
