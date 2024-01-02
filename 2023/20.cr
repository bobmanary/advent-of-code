["inputs/20_example1.txt", "inputs/20_example2.txt", "inputs/20.txt"].each do |filename|
  graph = parse(filename)
  puts "#{filename} part 1: #{part1(graph)}"

  # graph = parse(filename)
  # puts "#{filename} part 2: #{part2(graph)}"
end

def parse(filename)
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
  graph.add_nodes(nodes)
end

enum Pulse
  Low
  High
end

class Graph
  getter queue, pulse_count

  def initialize
    @nodes = Hash(String, Node).new
    @queue = Deque({String, Pulse, Array(String)}).new
    @pulse_count = StaticArray(Int32, 2).new(0)
  end

  def add_nodes(nodes)
    @nodes.merge! nodes
    nodes.each do |name, node|
      node.outputs.each do |target|
        @nodes[target].connect_input(name) if @nodes.has_key?(target)
      end
    end
    self
  end

  def push_button
    send("button", Pulse::Low, ["broadcaster"])
  end

  def send(source_name, pulse, outputs)
    # outputs.each do |target|
    #   ptext = pulse == Pulse::High ? "high" : "low"
    #   # puts "#{source_name} -#{ptext}-> #{target}"
    # end
    # puts "#{source.name} #{pulse.value} #{outputs.join(",")}"
    @pulse_count[pulse.value] += outputs.size
    @queue.push({source_name, pulse, outputs})
  end

  def process
    rx_count = 0
    while !@queue.empty?
      source_name, pulse, outputs = queue.shift
      outputs.each do |target|
        if target == "rx"
          rx_count += 1
        end
        @nodes[target].receive(pulse, source_name) if @nodes.has_key?(target)
      end
    end
    rx_count
  end
end

abstract class Node
  getter name
  getter! outputs : Array(String)
  abstract def initialize(@name : String, @outputs : Array(String), @graph : Graph)

  abstract def receive(pulse : Pulse, from : String)
  def send(pulse : Pulse)
    @graph.send(self.name, pulse, @outputs.not_nil!)
  end

  def connect_input(name)
  end
end

class FlipFlop < Node
  getter state

  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
    @state = false
  end
  def receive(pulse, from)
    if pulse == Pulse::Low
      @state = !@state
      send(@state ? Pulse::High : Pulse::Low)
    end
  end
end

class Conjunction < Node
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
    @state = Hash(String, Pulse).new(Pulse::Low)
  end

  # maybe wrong?
  def receive(pulse, from)
    @state[from] = pulse
    high_count = @state.values.count(Pulse::High)
    if high_count == @state.size
      send(Pulse::Low)
    else
      send(Pulse::High)
    end
  end

  def connect_input(name)
    @state[name] = Pulse::Low
  end
end

class Broadcaster < Node
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
  end
  def receive(pulse, from)
    send(pulse)
  end
end

class Output < Node
  def initialize(@name : String, @outputs : Array(String), @graph : Graph)
  end
  def receive(pulse, from)
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
  puts "\n"
  i = 0u32
  loop do
    graph.push_button
    i += 1
    if graph.process == 0
      break
    end
    print "\r#{i}" if i%10000 == 0
  end
  print "\n"
  i
end