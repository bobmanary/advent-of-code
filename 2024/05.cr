require "../2023/lib/dfs"
require "benchmark"

["inputs/05_test.txt", "inputs/05.txt"].each do |filename|
  orderings, updates = parse(filename)
  p1 = p2 = 0
  incorrect_updates = [] of Array(UInt8)

  Benchmark.ips do |bm|
    bm.report { p1, incorrect_updates = part1(orderings, updates) }
    bm.report { p2 = part2(orderings, incorrect_updates) }
  end

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

def parse(filename)
  orderings = [] of {UInt8, UInt8}
  updates = [] of Array(UInt8)
  is_order = true

  File.read(filename).lines.each do |line|
    if line == ""
      is_order = false
      next
    end
    
    if is_order
      a, b = line.split('|')
      orderings << {a.to_u8, b.to_u8}
    else
      updates << line.split(',').map &.to_u8
    end
  end 

  {orderings, updates}
end

def part1(orderings, updates) : { Int32, Array(Array(UInt8))}
  # will return a sum and a list of incorrectly-ordered updates to be used for part 2
  middle_page_sum = 0
  incorrect_updates = [] of Array(UInt8)
  updates.each_with_index do |update, i|
    valid_update = true
    update.each_with_index do |page_num, j|
      pages_before = orderings.select { |ordering| ordering[1] == page_num && update.includes?(ordering[0]) }.map &.[0]
      pages_after = orderings.select { |ordering| ordering[0] == page_num && update.includes?(ordering[1]) }.map &.[1]
      is_correct = pages_before.size == j && pages_after.size == update.size - j - 1
      if !is_correct
        valid_update = false
      end
    end

    if valid_update
      middle_page = update[update.size // 2]
      middle_page_sum += middle_page
    else
      incorrect_updates << update
    end
  end
  { middle_page_sum, incorrect_updates }
end

class Edge
  getter id : Int32
  getter value : UInt8
  getter edges : Array(Edge)
  def initialize(@id, @value)
    @edges = [] of Edge
  end
  def weight
    1
  end
  def add_edge(edge)
    @edges << edge
  end
end

def part2(orderings, incorrect_updates) : Int32
  middle_page_sum = 0

  incorrect_updates.each do |update|
    set = update.to_set
    edge_map = Hash(UInt8, Edge).new

    # filter out the rules that apply to this update
    relevant_rules = orderings.select {|ordering| set.includes?(ordering[0]) && set.includes?(ordering[1])}
    
    # create entries for each page with references to subsequent pages
    id = 0
    relevant_rules.each do |(first_page, next_page)|
      if !edge_map.has_key?(first_page)
        edge_map[first_page] = Edge.new(id, first_page)
        id += 1
      end
      if !edge_map.has_key?(next_page)
        edge_map[next_page] = Edge.new(id, next_page)
        id += 1
      end
      edge_map[first_page].add_edge(edge_map[next_page])
    end

    # ???
    ordered_update = Dfs(Edge).longest_path_nodes(edge_map.values).map(&.value).reverse
    middle_page_sum += ordered_update[ordered_update.size // 2]
  end

  middle_page_sum
end
