require "./lib/vector3d"
require "./lib/gnuplot"

class Line
  property p, q : Vector3d(Float64)
  def initialize(@p : Vector3d(Float64), @q : Vector3d(Float64))
  end

  def intersects_2d?(other : Line)
    # https://www.topcoder.com/thrive/articles/Geometry%20Concepts%20part%202:%20%20Line%20Intersection%20and%20its%20Applications#LineLineIntersection
    a1 = @q.y - @p.y
    b1 = @p.x - @q.x

    c1 = (a1 * @p.x) + (b1 * @p.y)
    
    a2 = other.q.y - other.p.y
    b2 = other.p.x - other.q.x

    c2 = (a2 * other.p.x) + (b2 * other.p.y)

    det = a1 * b2 - a2 * b1
    if det == 0
      return false, 0f64, 0f64
    else
      x = (b2 * c1 - b1 * c2) / det
      y = (a1 * c2 - a2 * c1) / det
      return true, x, y
    end
  end

  def as_vector
    return {@p, q_to_vector}
  end


  def q_to_vector
    # convert the line's second point back to to a vector
    vx = @q.x - @p.x
    vy = @q.y - @p.y
    vz = @q.z - @p.z

    Vector3d(Float64).new(vx, vy, vz)
  end

  def to_s(io)
    io << @p << " @ " << @q
  end

  def to_2d
    {@p.to_2d(exclude: :z), @q.to_2d(exclude: :z)}
  end

  def to_2d_vector
    {@p.to_2d(exclude: :z), q_to_vector.to_2d(exclude: :z)}
  end
end

def parse(input)
  input.lines.map do |line|
    n = line.split(/[\s@,]+/).map(&.to_f64)
    p = Vector3d(Float64).new(n[0], n[1], n[2])
    vector = Vector3d(Float64).new(n[3], n[4], n[5])
    q = p + vector

    Line.new(p, q)
  end
end

[
  {"inputs/24_example.txt", 7f64, 27f64},
  {"inputs/24.txt", 200000000000000f64, 400000000000000f64}
].each do |(filename, test_area_min, test_area_max)|
  input = File.read(filename)
  lines = parse(input)
  puts "#{filename} part 1: #{part1(lines, test_area_min, test_area_max)}"
end

def part1(lines, test_area_min, test_area_max)
  intersections = 0

  graph = Gnuplot::Vectors(Float64).new
  graph.add_box(
    Vector2d(Float64).new(test_area_min, test_area_min),
    Vector2d(Float64).new(test_area_max, test_area_max)
  )
  lines.each { |line| graph.add(*line.to_2d_vector) }

  lines.each_with_index do |line1, i|
    lines[i+1..].each_with_index(i+1) do |line2, j|
      lines_intersect, ix, iy = line1.intersects_2d?(line2)
      if lines_intersect
        if test_area_min <= ix <= test_area_max && test_area_min <= iy <= test_area_max
          v1 = line1.q_to_vector
          v2 = line2.q_to_vector

          # check if line1's intersection with line2 happened before line1's starting position
          line1_intersected_in_past = (ix > line1.p.x && v1.x < 0) || (ix < line1.p.x && v1.x > 0)
          line2_intersected_in_past = (ix > line2.p.x && v2.x < 0) || (ix < line2.p.x && v2.x > 0)

          if line1_intersected_in_past && line2_intersected_in_past
            # puts "\n#{line1}\n#{line2}\nHailstones' paths crossed in the past for both hailstones.\n"
          elsif line1_intersected_in_past
            # puts "\n#{line1}\n#{line2}\nHailstones' paths crossed in the past for hailstone A.\n"
          elsif line2_intersected_in_past
            # puts "\n#{line1}\n#{line2}\nHailstones' paths crossed in the past for hailstone B.\n"
          else
            # puts "\n#{line1}\n#{line2}\nHailstones' paths will cross inside the test area (at #{ix},#{iy}).\n"
            intersections += 1
          end
        else
          # puts "\n#{line1}\n#{line2}\nHailstones' paths will cross outside the test area (at #{ix},#{iy}).\n"
        end
      else
        # puts "\n#{line1}\n#{line2}\nHailstones' paths are parallel; they never intersect.\n"
      end
    end
  end
  graph.export("./temp/24")
  intersections
end
