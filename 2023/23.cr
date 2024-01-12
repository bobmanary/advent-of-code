require "./lib/asciimage"
require "./lib/dfs"

# parsing: convert the map grid into a graph of path segments (edges), each with a length
# part 1: DFS on the path segments weighted by length of the path
# part 2: convert the path graph into junction nodes with a separate distance
#         list between junctions and brute force a path recursively

class PathGraph
  @image : Asciimage
  @max_x : Int32
  @max_y : Int32
  @edges_by_start_xy : Hash(String, Edge)
  getter edges : Array(Edge)
  getter first, last : Edge

  def initialize(input : Array(Array(Char)))
    x = 0
    y = 0
    # find start
    startx = input[0].index('.')
    raise "oh no" if startx.nil?
    x = startx
    @max_x = input[0].size - 1
    @max_y = input.size - 1

    @edges = [] of Edge
    @edges_by_start_xy = Hash(String, Edge).new
    @image = parse_to_box_drawing(input)
    trace_edge(x, y+1, x, y, input)

    @first = @edges.first
    last = @edges.find {|edge| edge.edges.size == 0}
    raise "missing final edge?" if last.nil?
    @last = last
  end

  def trace_edge(x, y, prev_x, prev_y, input) : Edge
    if @edges_by_start_xy.has_key?("#{x},#{y}")
      return @edges_by_start_xy["#{x},#{y}"]
    end

    # use the junction-to-junction coordinates for first/last,
    # even though the first junction isn't counted in the path length
    first_x = prev_x # x
    first_y = prev_y # y

    path_length = 0
    coordinates = [] of {Int32, Int32}

    loop do
      # debug_digit = @edges.size.to_s.chars.last
      # @image.plot(x, y, debug_digit)
      # @image.render(true)
      # sleep 1.0 / 60.0

      path_length += 1
      coordinates << {x, y}

      next_tiles = [{x+1, y}, {x-1, y}, {x, y+1}, {x, y-1}]
      .reject do |(nx, ny)|
        (
          nx < 0 || ny < 0 ||
          nx > @max_x || ny > @max_y ||
          (nx == prev_x && ny == prev_y) ||
          !input[ny][nx].in_set?(".>v")
        )
      end

      if next_tiles.size == 1
        # this path continues
        prev_x = x
        prev_y = y
        x = next_tiles[0][0]
        y = next_tiles[0][1]
      else
        new_edge = add_edge(first_x, first_y, x, y, coordinates)
        next_tiles.each do |(nx, ny)|
          next if nx < x || ny < y # the input has no forks leading up or left without climbing
          new_edge.edges << trace_edge(nx, ny, x, y, input)
        end
        return new_edge
      end
    end
  end

  def add_edge(first_x, first_y, last_x, last_y, coordinates)
    # puts "adding edge #{@edges.size} #{coordinates}"

    # the second x/y coordinate is used instead of the first for purposes of looking up by starting point,
    # as the real first x/y is a junction whose coordinates are shared by multiple paths
    coord = coordinates[1]
    edge = Edge.new(first_x, first_y, last_x, last_y, @edges.size, coordinates, coordinates.size)
    @edges << edge
    @edges_by_start_xy["#{coord[0]},#{coord[1]}"] = edge
  end
end

class Edge
  getter x1, y1, x2, y2, id : Int32
  property weight : Int32
  getter edges : Array(Edge)
  getter coordinates : Array({Int32, Int32})

  def initialize(@x1 : Int32, @y1 : Int32, @x2 : Int32, @y2 : Int32, @id : Int32, @coordinates : Array({Int32, Int32}), length : Int32)
    @weight = length
    @edges = [] of Edge
  end
end

class JunctionGraph
  getter junctions, first, last

  def self.from(pg : PathGraph)
    junctions = Hash(Tuple(Int32, Int32), Junction).new(initial_capacity: pg.edges.size)

    first : Junction? = nil
    pg.edges.each do |edge1|
      j1 = if junctions.has_key?({edge1.x1, edge1.y1})
        junctions[{edge1.x1, edge1.y1}]
      else
        Junction.new(edge1.x1, edge1.y1, junctions.size)
      end

      j2 = if junctions.has_key?({edge1.x2, edge1.y2})
        junctions[{edge1.x2, edge1.y2}]
      else
        Junction.new(edge1.x2, edge1.y2, junctions.size)
      end

      first = j1 if junctions.empty?

      j1.distance[j2] = edge1.weight
      j2.distance[j1] = edge1.weight

      junctions[{j1.x, j1.y}] = j1
      junctions[{j2.x, j2.y}] = j2
    end

    last = junctions.values.find { |j| j.distance.size == 1 && j != first }
    raise "Missing first" if first.nil?
    raise "Missing last" if last.nil?

    new(junctions, first, last)
  end

  def initialize(@junctions : Hash(Tuple(Int32, Int32), Junction), @first : Junction, @last : Junction)
  end
end

class Junction
  getter x,y, id, distance
  def initialize(@x : Int32, @y : Int32, @id : Int32)
    @distance = Hash(Junction, Int32).new
  end
end


["inputs/23_example.txt", "inputs/23.txt"].each do |filename| #
  input = read(filename)
  map = parse_to_box_drawing(input)
  # map.render(true)

  graph1 = PathGraph.new(input)
  part1 = Dfs(Edge).longest_path(graph1.first, graph1.edges)
  puts "#{filename} part 1: #{part1}"

  jgraph = JunctionGraph.from(graph1)
  # print a dot graph for graphviz:
  # jgraph.junctions.each do |(x, y), j1|
  #   if j1.distance.size > 0
  #     j1.distance.each do |j2, distance|
  #       puts "j#{x}x#{y} -> j#{j2.x}x#{j2.y} [ label=\"#{distance}\"];"
  #     end
  #   else
  #     puts "j#{x}x#{y}"
  #   end
  # end

  expected = 6486 # 
  part2 = bruteforce(jgraph, input[0].size, input.size, map)
  if filename == "inputs/23.txt" && part2 != expected
    raise "got wrong answer #{part2}? :("
  end
  puts "#{filename} part 2: #{part2}"
end

def part1(graph)
  graph.first
  
end

# ─│ ┌ ┐└ ┘├ ┤ ┬ ┴ ┼
# attached edges defined as 0/1 for Left Bottom Right Top and used as an integer hash key
# eg ├ = 0111 = 7
BOXCHARS = {
  "1010".to_i(2) => '─',
  "0101".to_i(2) => '│',
  "0110".to_i(2) => '┌',
  "1100".to_i(2) => '┐',
  "0011".to_i(2) => '└',
  "1001".to_i(2) => '┘',
  "0111".to_i(2) => '├',
  "1101".to_i(2) => '┤',
  "1110".to_i(2) => '┬',
  "1011".to_i(2) => '┴',
  "1111".to_i(2) => '┼',
  "1000".to_i(2) => '╴',
  "0010".to_i(2) => '╶',
  "0001".to_i(2) => '╵',
  "0100".to_i(2) => '╷',
  0 => ' '
}

def read(filename)
  charray = File.read(filename).lines.map(&.chars)
end

def parse_to_box_drawing(charray : Array(Array(Char))) : Asciimage
  newmap = Asciimage.new(charray[0].size, charray.size)
  max_y = charray.size - 1
  max_x = charray[0].size - 1

  charray.each_with_index do |line, y|
    line.each_with_index do |char, x|
      boxchar = case char
        when '#' then ' '
        when '>' then '>'
        when 'v' then 'v'
        else
          left = if x > 0
            charray[y][x-1].in_set?("v>.") ? 1 : 0
          else
            0
          end
          down = if y < max_y
            charray[y+1][x].in_set?("v>.") ? 1 : 0
          else
            0
          end
          right = if x < max_x
            charray[y][x+1].in_set?("v>.") ? 1 : 0
          else
            0
          end
          up = if y > 0
            charray[y-1][x].in_set?("v>.") ? 1 : 0
          else
            0
          end

          begin
            symbol_key = [
              left, down, right, up
            ].join.to_i(2)


            BOXCHARS[symbol_key]
          rescue err : Exception
            puts "#{char}, #{x}, #{y}"
            raise err
          end
      end
      newmap.plot(x, y, boxchar)
    end
  end

  newmap
end

record BfState, stack : Array(Junction), depth : Int32, width : Int32, height : Int32, original_image : Asciimage, steps : Int32

def bruteforce(graph, map_width, map_height, original_image)
  visited_by_xy = Hash({Int32, Int32}, Bool).new(false)
  first = graph.first
  visited_by_xy[{first.x, first.y}] = true
  state = BfState.new([first], 0, map_width, map_height, original_image, 0)
  max, _ = bf_walk(first, graph.last, visited_by_xy, state)
  max
end


def bf_walk(junction, last, visited, state : BfState)
  if junction == last
    # render_stack(state)
    return 0, true
  end

  exit_count = 0
  max = junction.distance.reduce(0) do |acc, (junction2, j2_distance)|
    if !visited[{junction2.x, junction2.y}]
      visited2 = visited.clone
      visited2[{junction2.x, junction2.y}] = true
      state2 = state.copy_with(depth: state.depth + 1, stack: state.stack + [junction2], steps: state.steps + j2_distance)
      steps, found_exit = bf_walk(junction2, last, visited2, state2)
      if found_exit
        exit_count += 1
        Math.max(acc, j2_distance + steps)
      else
        acc
      end
    else
      acc
    end
  end

  return max, exit_count > 0
end

def render_stack(state)
  sum = 0
  image_full = Asciimage.new(state.original_image)

  state.stack.each_with_index do |junction, i|
    symbol = i.to_s(16).chars.last
    image_full.plot(junction.x, junction.y, symbol)
  end
  image_full.render(true)
end
