class Bfs(T)
  getter came_from : Hash(T, T?)
  @start : T
  def initialize(@start : T)
    frontier = Array(T).new
    frontier << @start
    came_from = Hash(T, T?).new
    came_from[@start] = nil

    while !frontier.empty?
      current = frontier.pop
      current.neighbors.each do |next_node|
        if !came_from.has_key?(next_node)
          frontier << next_node
          came_from[next_node] = current
        end
      end
    end
    @came_from = came_from
  end

  def find(goal)
    current = goal
    path = [] of T
    while current != @start
      path << current.as(T)
      current = @came_from[current]
    end
    path << @start
    path
  end
end
