def parse_and_normalize_input(str)
  str.lines.map do |line|
    rock = 'X'
    paper = 'Y'
    scissors = 'Z'
    second_shape_normalized = case line[2]
    when rock
      'A'
    when paper
      'B'
    else
      'C'
    end
    {line[0], second_shape_normalized }
  end
end

def parse_input(str)
  str.lines.map do |line| {line[0], line[2]} end
end

class Day2Part1
  def initialize(@plays : Array(Tuple(Char, Char)))
    rock = 'A'
    paper = 'B'
    scissors = 'C'
    point_map = {
      rock => 1,
      paper => 2,
      scissors => 3
    }

    scores = @plays.map do |(theirs, mine)|
      my_shape_score = point_map[mine]
      my_bonus_score = case
      when theirs == mine
        3
      when (theirs == rock && mine == scissors) || (theirs == scissors && mine == paper) || (theirs == paper && mine == rock)
        0
      else
        6
      end
      
      my_shape_score + my_bonus_score
    end
    puts scores.sum
  end
end

class Day2Part2
  def initialize(plays : Array(Tuple(Char, Char)))
    rock = 'A'
    paper = 'B'
    scissors = 'C'

    lose = 'X'
    draw = 'Y'
    win = 'Z'

    bonus_score_map = {
      lose => 0,
      draw => 3,
      win => 6
    }

    win_map = {
      rock => paper,
      paper => scissors,
      scissors => rock,
    }
    lose_map = win_map.invert

    point_map = {
      rock => 1,
      paper => 2,
      scissors => 3
    }

    scores = plays.map do |(theirs, outcome)|
      my_play = case outcome
      when lose
        lose_map[theirs]
      when win
        win_map[theirs]
      else # draw
        theirs
      end
      puts "#{theirs} #{my_play} => #{point_map[my_play]} + #{bonus_score_map[outcome]}"
      point_map[my_play] + bonus_score_map[outcome]
    end

    puts scores.sum
  end
end

test_input = parse_and_normalize_input("A Y
B X
C Z")
input = parse_and_normalize_input(File.read("inputs/02.txt"))
Day2Part1.new(test_input)
Day2Part1.new(input)

Day2Part2.new(parse_input("A Y
B X
C Z"))
Day2Part2.new(parse_input(File.read("inputs/02.txt")))