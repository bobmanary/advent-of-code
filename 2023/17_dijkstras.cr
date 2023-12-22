require "./lib/matrix"
require "./lib/priority_queue"
require "./lib/asciimage"
UINT32_MAX = 4_294_967_295

["inputs/17_example.txt"].each do |filename| #, "inputs/17.txt"
  graph, width, height = parse(filename)
  puts "#{filename} part 1: #{part1(graph, width, height)}"
  # puts "#{filename} part 2: #{part2(grid)}"
end

def part1(graph, width, height)
  start = graph.nodes[0]
  goal = graph.nodes[-1]
  came_from, cost_so_far = dijkstra_search(graph, start, goal)
  path = reconstruct_path(came_from, start, goal)
  image = Asciimage.new(width, height)
  path.each do |node|
    image.plot(node.x, node.y, node.heat_loss.to_s[0])
  end

  image.render
  path.reduce(0) { |acc, node| node.heat_loss + acc }
end

def dijkstra_search(graph, start, goal)
  frontier = PriorityQueue(MapNode).new
  frontier.put(start, 0)
  came_from = Hash(MapNode, MapNode?).new
  cost_so_far = Hash(MapNode, Int32).new
  came_from[start] = nil
  cost_so_far[start] = 0

  while !frontier.empty?
    current = frontier.get()

    if current == goal
      break
    end

    current.edges.each do |next_node|
      # next if next_node == came_from[current]
      new_cost = cost_so_far[current] + next_node.heat_loss
      if !cost_so_far.has_key?(next_node) || new_cost < cost_so_far[next_node]
        cost_so_far[next_node] = new_cost
        priority = new_cost
        frontier.put(next_node, priority)
        came_from[next_node] = current
      end
    end
  end

  return came_from, cost_so_far
end

def reconstruct_path(came_from : Hash(MapNode, MapNode?), start : MapNode, goal : MapNode) : Array(MapNode)
  current : MapNode = goal
  path  = [] of MapNode

  if !came_from.has_key?(goal)
    return path
  end

  while current != start
    path << current
    current = came_from[current].as(MapNode)
  end
  path << start
  path.reverse
end

def parse(filename)
  width = height = 0
  graph = Graph.new

  File.open(filename) do |f|
    width = f.read_line.size
    f.rewind
    height = (f.size // (width + 1)).to_i32
    nodes = Matrix(MapNode).new(width, height)

    x = y = id = 0
    f.each_char do |c|
      if c == '\n'
        x = 0
        y += 1
        next
      end
      node = MapNode.new(c.to_i32, id, x, y)
      nodes << node
      x += 1
      id += 1
    end

    nodes.each do |node, x, y|
      nodes.neighbors(x, y).each do |nb|
        node.add_edge(nb)
      end
    end

    graph.add(nodes)
  end

  return graph, width, height
end

class Graph
  getter nodes
  def initialize
    @nodes = [] of MapNode
  end

  def add(other : Matrix)
    @nodes.concat(other.array)
    self
  end

  def each(&block)
    if block.nil?
      @nodes.each
    else
      @nodes.each { |node| yield node }
    end
  end
end

class MapNode
  getter heat_loss : Int32
  getter edges : Array(MapNode)
  getter id : Int32
  getter x : Int32
  getter y : Int32
  def initialize(@heat_loss, @id, @x, @y)
    @edges = Array(MapNode).new(4)
  end

  def add_edge(other : MapNode)
    @edges << other
  end
end
