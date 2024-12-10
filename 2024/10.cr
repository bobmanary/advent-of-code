require "benchmark"
["inputs/10_test1.txt", "inputs/10_test2.txt", "inputs/10_test3.txt", "inputs/10.txt"].each do |filename|
  trailheads = all_nodes = [] of Node
  node_count = p1 = p2 = 0
  Benchmark.ips do |bm|
    bm.report { trailheads, node_count, all_nodes = parse(filename)}
    bm.report { p1 = part1(trailheads, node_count) }
    bm.report { p2 = part2(trailheads, node_count, all_nodes) }
  end

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
  all_nodes = [] of Node
  File.read(filename).lines.map do |line|
    row = Array(Node).new
    map << row
    line.chars.each do |char|
      node = Node.new(id, char.to_u8)
      id += 1
      row << node
      trailheads << node if node.value == 0u8
      all_nodes << node
    end
  end

  map.each_with_index do |row, y|
    row.each_with_index do |node, x|
      node.add_edges(find_edges(node, map, x, y))
    end
  end

  {trailheads, id, all_nodes}
end

def find_edges(node, map, orig_x, orig_y)
  max_x = map[0].size - 1
  max_y = map.size - 1
  edges = [] of Node
  [{1, 0}, {0, 1}, {-1, 0}, {0, -1}].each do |(offset_x, offset_y)|
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
  stack = Deque(Node).new
  scores = Array(Int32).new(trailheads.size, 0)
  trailheads.each_with_index do |node, i|
    accessible_peaks = Array(Bool).new(node_count, false)
    visited = Array(Bool).new(node_count, false)
    visit(node, visited, accessible_peaks)
    scores[i] = accessible_peaks.count(true)
  end

  scores.sum
end

def visit(node, visited, accessible_peaks)
  return if visited[node.id]
  visited[node.id] = true

  if node.value == 9
    accessible_peaks[node.id] = true
    return
  end
  node.edges.each do |edge|
    visit(edge, visited, accessible_peaks)
  end
end


def part2(trailheads, node_count, all_nodes)
  visited = Array(Bool).new(node_count, false)
  unique_path_counts = Array(Int32).new(node_count, 0)
  trailheads.each do |node|
    visit2(node, visited, unique_path_counts)
  end

  # graphviz
  File.open("temp/10_part2.dot", "w") do |file|
    file << "digraph MountainPaths {\n"
    all_nodes.each do |node|
      edges = node.edges.map {|edge| "n#{edge.id}"}
      file << "  n#{node.id} -> {#{edges.join(' ')}}[label=\"#{unique_path_counts[node.id]}\"];\n"
    end
    file << "}\n"
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
  else
    unique_path_counts[node.id] = node.edges.reduce(0) do |acc, edge|
      acc + visit2(edge, visited, unique_path_counts)
    end
    return unique_path_counts[node.id]
  end
end
