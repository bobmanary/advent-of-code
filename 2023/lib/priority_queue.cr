class PriorityQueue(T) < Array({T, Int32})
  def put(node, priority)
    # high effort, high efficiency
    self << {node, priority}
    sort! { |a, b| b[1] <=> a[1] }
  end

  def get : T
    pair = pop
    pair[0]
  end
end
