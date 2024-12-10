require "benchmark"
require "bit_array"
#"inputs/10_test1.txt", "inputs/10_test2.txt", "inputs/10_test3.txt", 
["inputs/10.txt"].each do |filename|
  trailheads = [] of Node
  node_count = p1 = p2 = 0

  Benchmark.ips do |bm|
    bm.report { trailheads, node_count = parse(filename)}
    bm.report { p1 = part1(trailheads, node_count) }
    bm.report { p2 = part2(trailheads, node_count) }
  end
  # trailheads, node_count, all_nodes = parse(filename)
  # p1 = part1(trailheads, node_count)
  # p2 = part2(trailheads, node_count, all_nodes)

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

class Node
  getter edges : Array(Node)
  getter id : Int32
  getter value : UInt8
  def initialize(@id, @value)
    @edges = Array(Node).new
  end
  def add_edges(nodes)
    @edges.concat(nodes)
  end
end

def parse(filename)
  id = 0
  map = Array(Array(Node)).new
  trailheads = [] of Node
  File.read(filename).lines.map do |line|
    row = Array(Node).new
    map << row
    line.chars.each do |char|
      node = Node.new(id, char.to_u8)
      id += 1
      row << node
      trailheads << node if node.value == 0u8
    end
  end

  map.each_with_index do |row, y|
    row.each_with_index do |node, x|
      node.add_edges(find_edges(node, map, x, y))
    end
  end

  {trailheads, id}
end

DIR_OFFSETS = [{1, 0}, {0, 1}, {-1, 0}, {0, -1}]

def find_edges(node, map, orig_x, orig_y)
  max_x = map[0].size - 1
  max_y = map.size - 1
  edges = [] of Node
  DIR_OFFSETS.each do |(offset_x, offset_y)|
    x = orig_x + offset_x
    y = orig_y + offset_y
    next if x < 0 || y < 0 || x > max_x || y > max_y
    maybe_edge = map[y][x]
    if maybe_edge.value == node.value + 1
      edges << maybe_edge
    end
  end
  edges
end

def part1(trailheads, node_count)
  scores = Array(Int32).new(node_count, 0)
  accessible_peak_ids = Array(Array(Int32)).new(node_count) {[] of Int32}
  visited = BitArray.new(node_count, false)

  trailheads.reduce(0) do |acc, node|
    acc + visit(node, visited, accessible_peak_ids).uniq.size
  end
end

def visit(node, visited, accessible_peak_ids)
  return accessible_peak_ids[node.id] if visited[node.id]
  visited[node.id] = true

  if node.value == 9
    accessible_peak_ids[node.id] << node.id
    return accessible_peak_ids[node.id]
  end

  peaks = [] of Int32
  node.edges.each do |edge|
    peaks.concat(visit(edge, visited, accessible_peak_ids))
  end

  accessible_peak_ids[node.id] = peaks
  peaks
end

def part2(trailheads, node_count)
  visited = BitArray.new(node_count, false)
  unique_path_counts = Array(Int32).new(node_count, 0)
  trailheads.each do |node|
    visit2(node, visited, unique_path_counts)
  end

  trailheads.reduce(0) do |acc, node|
    acc + unique_path_counts[node.id]
  end
end

def visit2(node, visited, unique_path_counts)
  return unique_path_counts[node.id] if visited[node.id]
  visited[node.id] = true

  if node.value == 9
    unique_path_counts[node.id] = 1
    return 1
  end

  unique_path_counts[node.id] = node.edges.reduce(0) do |acc, edge|
    acc + visit2(edge, visited, unique_path_counts)
  end
  return unique_path_counts[node.id]
end
