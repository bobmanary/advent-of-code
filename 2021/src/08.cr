require "option_parser"

filename = ""

OptionParser.parse do |parser|
  parser.on "-f NAME", "--file", "Filename" do |name|
    filename = name
  end
end

class Puzzle
  getter input : Array(Array(String))
  def initialize(filename)
    @input = File.read(filename).lines.to_a.map do |line|
      line.split(" | ").last.split(' ').map do |str| str.chars.sort.join("") end
    end
  end

  def run
    count = 0
    @input.each do |line|
      line.each do |str|
        if [2, 3, 4, 7].includes?(str.size)
          count += 1
        end
      end
    end

    @input.each do |input_line|
      puts input_line
    end

    puts count
  end
end


class Puzzle2
  getter input : Array(Array(String))

  def initialize(filename)
    @input = File.read(filename).lines.to_a.map do |line|
      line.split(" | ").last.split(' ').map do |str| str.chars.sort.join("") end
    end
  end

  def run
    count = 0
    puts "input: #{@input}"
    @input.each do |line|
      segment_finder = SegmentFinder.new
      line.each do |str|
        segment_finder.add(str)# if [2, 3, 4, 7].includes?(str.size)
      end
      puts "#{line}:"
      pp segment_finder
    end

    # @input.each do |input_line|
    #   puts input_line
    # end

    puts count
  end
end

class SegmentFinder
#   8:      9:
#
#  aaaa    aaaa
# b    c  b    c
# b    c  b    c
#  dddd    dddd
# e    f  .    f
# e    f  .    f
#  gggg    gggg
  getter segments : Hash(Char, Array(Char))
  def initialize()
    @segments = Hash(Char, Array(Char)).new
    "abcdefg".chars
      .each do |char|
        @segments[char] = "abcdefg".chars
      end
  end

  def add(str)
    case str.size
    when 2
      # "1"
      remove_potentials("cf", str)
    when 3
      # "7"
      remove_potentials("acf", str)
    when 4
      # "4"
      remove_potentials("bdcf", str)
    # when 7
    #   # "8"
    #   remove_potentials("")
    end
  end

  def remove_potentials(segment_keys, str)
    segment_keys.chars.each do |segment_key|
      @segments[segment_key].reject!  { |potential_char| str.chars.includes?(potential_char) }
    end
  end
end

puts Puzzle.new(filename).run
puts Puzzle2.new(filename).run
