require "./priority_queue"
class DijkstraSearch(T)
  getter came_from : Hash(T, T?)
  getter cost_so_far : Hash(T, Int32)

  def initialize(@start : T, &cost_function : T -> Int32)
    frontier = PriorityQueue(T).new
    frontier.put(@start, 0)
    @came_from = Hash(T, T?).new
    @cost_so_far = Hash(T, Int32).new
    @came_from[@start] = nil
    @cost_so_far[@start] = 0

    while !frontier.empty?
      current = frontier.get()

      current.neighbors.each do |next_node|
        new_cost = @cost_so_far[current] + cost_function.call(next_node)
        if !@cost_so_far.has_key?(next_node) || new_cost < @cost_so_far[next_node]
          @cost_so_far[next_node] = new_cost
          priority = new_cost
          frontier.put(next_node, priority)
          @came_from[next_node] = current
        end
      end
    end
  end

  def find(goal : T)
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
