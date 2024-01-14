require "./lib/dijkstra_search"

["inputs/25_example.txt", "inputs/25.txt"].each do |filename|
  graph, links = parse(filename)
  p1 = part1(graph, links)
  puts "#{filename} part 1: #{p1}"
end

class Node
  getter neighbors : Set(Node)
  getter id : String
  def initialize(@id : String)
    @neighbors = Set(Node).new
  end
end

def parse(filename)
  graph = Hash(String, Node).new

  File.read(filename).lines.each do |line|
    lname, rnames = line.split(": ")

    rnames.split(' ').each do |rname|
      add_link(graph, lname, rname)
    end
  end

  links = Set({Node, Node}).new
  graph.each do |k, node|
    node.neighbors.each do |linked_node|
      if node.id < linked_node.id
        links << {node, linked_node}
      else
        links << {linked_node, node}
      end
    end
  end

  links.to_a.sort do |a, b|
    a[0].id <=> b[0].id
  end

  return graph, links
end

def add_link(hash, lname, rname)
  lnode = hash.has_key?(lname) ? hash[lname] : (hash[lname] = Node.new(lname))
  rnode = hash.has_key?(rname) ? hash[rname] : (hash[rname] = Node.new(rname))

  lnode.neighbors << rnode
  rnode.neighbors << lnode
end

def part1(graph : Hash(String, Node), links : Set({Node, Node}))
  # do a dijkstra search from each node to each other node, see which edges have the most visits,
  # then remove the top 3 visited edges
  nodes = graph.values
  edge_visits = Hash({Node, Node}, Int32).new(0)
  graph_size = graph.size

  nodes.each_with_index do |start, i|
    # puts "searching from #{start.id} (#{i+1}/#{graph_size})"
    dijkstra = DijkstraSearch(Node).new(start) { 1 }
    nodes[i..].each do |goal|
      path = dijkstra.find(goal)

      path.each_cons_pair do |a, b|
        edge = if a.id < b.id
          {a, b}
        else
          {b, a}
        end
        edge_visits[edge] += 1
      end
    end
  end

  # see which edges have the most visits
  sorted_visits = edge_visits.to_a.sort! { |(edge1, count1), (edge2, count2)| count1 <=> count2 }
  top_visits = sorted_visits.last(3)
  # top_visits.each do |((lnode, rnode), count)|
  #   puts "#{lnode.id}-#{rnode.id}: #{count}"
  # end

  top_visits.each do |((lnode, rnode), count)|
    lnode.neighbors.delete(rnode)
    rnode.neighbors.delete(lnode)
  end
  lnode = top_visits[0][0][0]
  rnode = top_visits[0][0][1]
  left_graph = DijkstraSearch(Node).new(lnode) { 1 }
  if left_graph.came_from.has_key?(rnode)
    raise "Graph was not split!"
  end
  right_graph = DijkstraSearch(Node).new(rnode) { 1 }

  # puts "graph sizes: #{left_graph.came_from.size}, #{right_graph.came_from.size}"
  left_graph.came_from.size * right_graph.came_from.size
end
