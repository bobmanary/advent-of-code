test = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"

class CubePull
  getter red : Int32 = 0
  getter green : Int32 = 0
  getter blue : Int32 = 0

  def initialize(text_record)
    text_record.split(", ").each do |cube_stat|
      numeric, colour = cube_stat.split(" ")


      if numeric.nil? || colour.nil?
        raise "invalid cube_stat: #{cube_stat}"
      end

      cube_count = numeric.to_i
      if    colour == "red"   && cube_count > @red
        @red   = cube_count
      elsif colour == "green" && cube_count > @green
        @green = cube_count
      elsif colour =="blue"   && cube_count > @blue
        @blue  = cube_count
      else
        raise "invalid cube colour: '#{colour}'"
      end
    end
  end

  def contained_max_cubes?(red, green, blue)
    result = @red <= red && @green <= green && @blue <= blue
    #puts "#{@red} #{@green} #{@blue}: #{result}"
    result
  end
end

class CubeGameRecord
  getter game_number : Int32
  getter contained : Bool = true
  getter pulls = [] of CubePull

  def initialize(text_record : String, red_max : Int32, green_max : Int32, blue_max : Int32)

    number, pulls = text_record.split(": ")

    if number.nil? || pulls.nil?
      raise "invalid game: #{text_record}"
    end

    @game_number = number.split(' ').last.to_i
    
    pulls.split("; ").each do |pull_record|
      pull = CubePull.new(pull_record)
      @pulls << pull
      @contained = false unless pull.contained_max_cubes?(red_max, green_max, blue_max)
    end

    #puts "Game #{@game_number}: #{@contained}\n\n"
  end

  def power
    r = g = b = 0

    @pulls.each do |pull|
      r = pull.red if r < pull.red
      g = pull.green if g < pull.green
      b = pull.blue if b < pull.blue
    end
    r * b * g
  end
end

def parse1(input)
  games = input.lines.map do |line|
    CubeGameRecord.new(line, 12, 13, 14)
  end
  puts games.select { |game| game.contained }.sum(0) { |game| game.game_number }
end

def parse2(input)
  games = input.lines.map do |line|
    CubeGameRecord.new(line, Int32::MAX, Int32::MAX, Int32::MAX)
  end

  puts games.sum(0) { |game| game.power }
end

parse1(test)
parse1(File.read("inputs/02.txt"))

parse2(test)
parse2(File.read("inputs/02.txt"))