class Stepper
  def initialize(@steps : String)
    @pointer = -1
  end

  def next
    @pointer += 1
    if @pointer >= @steps.size
      @pointer = 0
    end
    @steps[@pointer]
  end

  def reset
    @pointer = -1
  end

  def length
    @steps.size
  end
end

["inputs/08_example.txt", "inputs/08_example2.txt", "inputs/08_example3.txt", "inputs/08.txt"].each do |filename|
  input = File.read(filename).lines
  stepper = Stepper.new(input.first)

  nodes = input[2..].map do |line|
    line.match(/(\w{3}) = \((\w{3}), (\w{3})\)/)
    name, left, right = $~[1..3]
    {name, {left, right}}
  end.to_h

  # part 1
  current_node = nodes.fetch("AAA", nil)
  if current_node.is_a?(Tuple(String, String))
    steps = follow_path("AAA", stepper, nodes) { |next_node| next_node == "ZZZ" }
    puts "#{filename} part 1: #{steps}"
  end

  # part 2
  current_nodes = nodes.select {|k, v| k[2] == 'A'}
  unless current_nodes.empty?
    name, next_nodes = current_nodes.first
    path_steps_to_z = [] of UInt64

    # paths cycle after finding a Z node without revisiting an A node,
    # but the cycles appear to be the same length as the initial path
    current_nodes.each do |starting_name, (left, right)|
      stepper.reset
      path_steps_to_z << follow_path(starting_name, stepper, nodes) {|next_node| next_node[2] == 'Z'}
    end

    puts "#{filename} part 2: #{lcm_fast(path_steps_to_z)}"
  end
end

def find_lcm(path_steps_to_z)
  # my implementation, works but slow
  max_steps = path_steps_to_z.max
  lcm = max_steps
  other_steps = path_steps_to_z - [max_steps]

  while true
    lcm += max_steps
    break if other_steps.all? {|s| lcm % s == 0 }
  end

  lcm
end

def lcm_fast(paths : Array(UInt64)) : UInt64
  # taken from https://github.com/TheAlgorithms/Rust/blob/master/src/math/lcm_of_n_numbers.rs
  return paths[0] if paths.size == 1

  a = paths[0]
  b = lcm_fast(paths[1..])
  a * b // gcd_of_two_numbers(a, b)
end

def gcd_of_two_numbers(a, b) : UInt64
  return a if b == 0
  gcd_of_two_numbers(b, a % b)
end


def follow_path(starting_node_name, stepper, nodes) : UInt64
  steps = 0u64
  current_node = nodes[starting_node_name]
  while true
    direction = stepper.next
    next_node = if direction == 'L'
      current_node[0]
    else
      current_node[1]
    end
    steps += 1
    current_node = nodes[next_node]

    break if yield(next_node)
  end

  steps
end
