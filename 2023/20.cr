["inputs/20_example1.txt", "inputs/20_example2.txt", "inputs/20.txt"].each do |filename|
  graph = parse(filename)
  puts "#{filename} part 1: #{part1(graph)}"

  next unless filename == "inputs/20.txt"
  graph = parse(filename, true)
  puts "#{filename} part 2: #{part2(graph)}"
end

def parse(filename, find_output_nodes : Bool = false)
  graph = Graph.new
  nodes = File.read(filename).lines.map do |line|
    label, _, outputs = line.partition(" -> ")
    case label[0]
      when '%' then {label[1..], FlipFlop.new(label[1..], outputs.split(", "), graph)}
      when '&' then {label[1..], Conjunction.new(label[1..], outputs.split(", "), graph)}
      else {label, Broadcaster.new(label, outputs.split(", "), graph)}
    end
  end.to_h
  graph.add_nodes({"output" => Output.new("output", [] of String, graph)})
  graph.add_nodes(nodes, find_output_nodes)
end

enum Pulse
  Low
  High
end

class Graph
  getter queue, pulse_count, nodes
  getter conjunctions : Hash(String, Conjunction)

  def initialize
    @nodes = Hash(String, Node).new
    @conjunctions = Hash(String, Conjunction).new
    @queue = Deque({String, Pulse, Array(String)}).new
    @pulse_count = StaticArray(Int32, 2).new(0)
  end

  def add_nodes(nodes, find_output_nodes : Bool = false)
    @nodes.merge! nodes
    nodes.each do |name, node|
      node.outputs.each do |target|
        @nodes[target].connect_input(name) if @nodes.has_key?(target)
      end
    end

    if find_output_nodes
      final_conjunction = @nodes.find {|k, node| node.outputs == ["rx"] }
      raise "could not find output to rx" if final_conjunction.nil?

      @nodes.each do |name, node|
        @conjunctions[name] = node if node.is_a?(Conjunction) && node.outputs == [final_conjunction[0]]
      end
    end

    self
  end

  def push_button
    send_pulse("button", Pulse::Low, ["broadcaster"])
  end

  def send_pulse(source_name, pulse, outputs)
    @pulse_count[pulse.value] += outputs.size
    @queue.push({source_name, pulse, outputs})
  end

  def process
    while !@queue.empty?
      source_name, pulse, outputs = queue.shift
      outputs.each do |target|
        if @nodes.has_key?(target)
          @nodes[target].receive_pulse(pulse, source_name)
        end
      end
    end
  end

  def process(&block)
    # same as process(), but call a block when one of the final conjunctions to output
    # receives a high pulse
    while !@queue.empty?
      source_name, pulse, outputs = queue.shift
      outputs.each do |target|
        if @nodes.has_key?(target)
          @nodes[target].receive_pulse(pulse, source_name)
          if pulse.high? && @conjunctions.has_key?(source_name)
            yield @nodes[source_name]
          end
        end
      end
    end
  end
end

abstract class Node
  getter name : String
  getter! outputs : Array(String)
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
  end

  abstract def receive_pulse(pulse : Pulse, from : String)

  def send_pulse(pulse : Pulse)
    @graph.send_pulse(self.name, pulse, @outputs.not_nil!)
  end

  def connect_input(name)
  end
end

class FlipFlop < Node
  getter state

  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
    @state = false
  end

  def receive_pulse(pulse : Pulse, from : String)
    if pulse == Pulse::Low
      @state = !@state
      send_pulse(@state ? Pulse::High : Pulse::Low)
    end
  end
end

class Conjunction < Node
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
    @state = Hash(String, Pulse).new(Pulse::Low)
  end

  def receive_pulse(pulse : Pulse, from : String)
    @state[from] = pulse
    high_count = @state.values.count(Pulse::High)
    if high_count == @state.size
      send_pulse(Pulse::Low)
    else
      send_pulse(Pulse::High)
    end
  end

  def connect_input(name)
    @state[name] = Pulse::Low
  end

  def high_pulse_count
    @state.values.count(Pulse::High)
  end
end

class Broadcaster < Node
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
  end
  def receive_pulse(pulse : Pulse, from : String)
    send_pulse(pulse)
  end
end

class Output < Node
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
  end

  def receive_pulse(pulse : Pulse, from : String)
  end
end

def part1(graph)
  1000.times do
    graph.push_button
    graph.process
  end
  graph.pulse_count[0] * graph.pulse_count[1]
end

def part2(graph)
  first_high_pulses = Hash(String, UInt64).new
  i = 0u64

  while first_high_pulses.size < graph.conjunctions.size
    i += 1
    graph.push_button
    graph.process do |node|
      next if first_high_pulses.has_key?(node.name)
      # puts "#{node.name} sent high pulse at #{i}"
      first_high_pulses[node.name] = i
    end
  end
  lcm(first_high_pulses.values)
end

def lcm(numbers)
  a = numbers[0]
  return a if numbers.size == 1
  b = lcm(numbers[1..])
  a.lcm(b)
end
