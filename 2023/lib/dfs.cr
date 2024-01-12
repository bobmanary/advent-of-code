module Dfs(T)
  def self.topological_sort(node : T, visited : Array(Bool), stack : Array(T))
    visited[node.id] = true

    node.edges.each do |edge|
      if !visited[edge.id]
        topological_sort(edge, visited, stack)
      end
    end

    stack << node
  end

  def self.longest_path(source : T, nodes : Array(T))
    stack = Array(T).new
    dist = Array(Int32).new(nodes.size, Int32::MIN) # dist = distance
    visited = Array(Bool).new(nodes.size, false)

    nodes.each do |node|
      if !visited[node.id]
        topological_sort(node, visited, stack)
      end
    end

    dist[source.id] = source.weight

    while stack.size > 0
      node = stack.pop
      if dist[node.id] != Int32::MIN
        node.edges.each do |edge|
          if dist[edge.id] < dist[node.id] + edge.weight
            dist[edge.id] = dist[node.id] + edge.weight
          end
        end
      end
    end

    dist.max
  end
end
