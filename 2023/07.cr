["inputs/07_example.txt", "inputs/07.txt"].each do |filename|
  inputs = File.read(filename).lines
  puts "#{filename} part 1: #{calculate_winnings(inputs, false)}"
  puts "#{filename} part 2: #{calculate_winnings(inputs, true)}"
end

CARD_VALUES = "23456789TJQKA".chars.each_with_index.map {|char, i| {char, i} }.to_h
CARD_VALUES_JOKER = "J23456789TQKA".chars.each_with_index.map {|char, i| {char, i} }.to_h
def sort(hands, jokers_wild : Bool)
  hands.sort! do |a, b|
    result = get_hand_type_value(a, jokers_wild) <=> get_hand_type_value(b, jokers_wild)
    if result == 0
      compare_hand_card_value(a, b, jokers_wild)
    else
      result
    end
  end
end

def calculate_winnings(inputs, jokers_wild : Bool)
  hands = [] of String
  bids = Hash(String, Int32).new

  inputs.each do |input|
    temp = input.split(" ")
    hand = temp[0]
    bid = temp[1].to_i
    
    bids[hand] = bid
    hands << hand
  end

  sort(hands, jokers_wild)
  hands.each do |h| puts h end

  hands.each_with_index.reduce(0) do |acc, (hand, i)|
    rank = i+1
    acc + rank * bids[hand]
  end
end

def compare_hand_card_value(a, b, jokers_wild)
  5.times do |i|
    result = if jokers_wild
      CARD_VALUES_JOKER[a[i]] <=> CARD_VALUES_JOKER[b[i]]
    else
      CARD_VALUES[a[i]] <=> CARD_VALUES[b[i]]
    end
    return result unless result == 0
  end
  0
end

def get_hand_type_value(hand, jokers_wild : Bool = false)
  if jokers_wild
    rules = Rules2.new(hand)
  else
    rules = Rules.new(hand)
  end

  rules.hand_value
end

class Rules
  property hand_map : Hash(Char, Int32)
  property hand : String
  
  def initialize(@hand)
    @hand_map = @hand.chars.group_by {|c| c}.transform_values(&.size)
  end

  def five_of_a_kind?
    hand_map.size == 1
  end

  def four_of_a_kind?
    hand_map.values.includes?(4)
  end

  def full_house?
    hand_map.size == 2 && hand_map.values.includes?(3)
  end

  def three_of_a_kind?
    hand_map.size == 3 && hand_map.values.includes?(3)
  end

  def two_pair?
    hand_map.size == 3 && hand_map.values.select {|v| v == 2}.size == 2
  end

  def one_pair?
    hand_map.size == 4
  end

  def high_card?
    hand_map.size == 5
  end

  def hand_value
    case self
    when .five_of_a_kind?
      7
    when .four_of_a_kind?
      6
    when .full_house?
      5
    when .three_of_a_kind?
      4
    when .two_pair?
      3
    when .one_pair?
      2
    when .high_card?
      1
    else
      raise "wtf"
    end
  end
end

class Rules2 < Rules
  def jw_five_of_a_kind?
    five_of_a_kind? || (
      (four_of_a_kind? && hand_map.fetch('J', 0) == 1) ||
      (four_of_a_kind? && hand_map.fetch('J', 0) == 4) ||
      (full_house? && hand_map.fetch('J', 0) > 0)
    )
  end

  def jw_four_of_a_kind?
    four_of_a_kind? || (
      (three_of_a_kind? && hand_map.fetch('J', 0) == 1) ||
      (three_of_a_kind? && hand_map.fetch('J', 0) == 3) ||
      (two_pair? && hand_map.fetch('J', 0) == 2 && hand_map.size == 3)
    )
  end

  def jw_full_house?
    full_house? || (
      two_pair? && hand_map.fetch('J', 0) == 1
    )
  end

  def jw_three_of_a_kind?
    three_of_a_kind? || (
      (one_pair? && hand_map.fetch('J', 0) == 1) ||
      (one_pair? && hand_map.fetch('J', 0) == 2)
    )
  end

  def jw_two_pair?
    two_pair?
  end

  def jw_one_pair?
    one_pair? || (
      hand_map.fetch('J', 0) == 1
    )
  end

  def jw_high_card?
    high_card?
  end

  def hand_value
    case self
    when .jw_five_of_a_kind?
      7
    when .jw_four_of_a_kind?
      6
    when .jw_full_house?
      5
    when .jw_three_of_a_kind?
      4
    when .jw_two_pair?
      3
    when .jw_one_pair?
      2
    when .jw_high_card?
      1
    else
      raise "wtf"
    end
  end
end
