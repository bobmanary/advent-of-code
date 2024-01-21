require "./lib/vector3d"
require "./lib/gnuplot"

alias Vec3 = Vector3d(Float64)

[
  # {"inputs/24_example.txt", 7f64, 27f64, 10f64, false},
  {"inputs/24.txt", 200000000000000f64, 400000000000000f64, 2600000000000f64, true}
].each do |(filename, test_area_min, test_area_max, max_iterations, use_proportional_iteration)|
  input = File.read(filename)
  lines = parse(input)
  # puts "#{filename} part 1: #{part1(lines, test_area_min, test_area_max)}"

  part2(lines, test_area_max, max_iterations, use_proportional_iteration)
end


class Line
  property p, q : Vec3
  def initialize(@p : Vec3, @q : Vec3)
  end

  def initialize(components : Array(Float64))
    @p = Vec3.new(components[0], components[1], components[2])
    @q = Vec3.new(components[3], components[4], components[5])
  end

  def intersects_2d?(other : Line, exclude : Symbol)
    # https://www.topcoder.com/thrive/articles/Geometry%20Concepts%20part%202:%20%20Line%20Intersection%20and%20its%20Applications#LineLineIntersection

    my_components = [p.x, @p.y, @p.z, @q.x, @q.y, @q.z]
    other_components = [other.p.x, other.p.y, other.p.z, other.q.x, other.q.y, other.q.z]

    delete_indexes = case exclude
    when :x then [3, 0]
    when :y then [4, 1]
    when :z then [5, 2]
    else
      raise "exclude must be one of :x, :y, :z"
    end

    my_components.delete_at(delete_indexes[0])
    my_components.delete_at(delete_indexes[1])
    other_components.delete_at(delete_indexes[0])
    other_components.delete_at(delete_indexes[1])
    # components should now be [x1, y1, x2, y2] if z is excluded, and so on

    # a1 = @q.y - @p.y
    a1 = my_components[3] - my_components[1]
    # b1 = @p.x - @q.x
    b1 = my_components[0] - my_components[2]

    # c1 = (a1 * @p.x) + (b1 * @p.y)
    c1 = (a1 * my_components[0]) + (b1 * my_components[1])
    
    # a2 = other.q.y - other.p.y
    a2 = other_components[3] - other_components[1]
    # b2 = other.p.x - other.q.x
    b2 = other_components[0] - other_components[2]

    # c2 = (a2 * other.p.x) + (b2 * other.p.y)
    c2 = (a2 * other_components[0]) + (b2 * other_components[1])

    det = a1 * b2 - a2 * b1
    if det == 0
      return false, 0f64, 0f64
    else
      x = (b2 * c1 - b1 * c2) / det
      y = (a1 * c2 - a2 * c1) / det
      return true, x, y
    end
  end

  def skew_lines_distance(other)
    u1 = direction
    u2 = other.direction
    u3 = u1.cross(u2)
    if u3.magnitude == 0f64
      return 0f64
    end
    u3.normalize!
    dir = @p - other.p
    (dir.dot(u3)).abs
  end

  # get the two points on line1 and line2 that are closest to each other
  def nearest_points(line2) : { Vec3, Vec3 }
    # https://en.wikipedia.org/wiki/Skew_lines#Nearest_points

    line1 = self
    # check if lines touch at one of the points
    if line1.p == line2.p || line1.p == line2.q
      return {line1.p.clone, line1.p.clone}
    elsif line1.q == line2.p || line1.q == line2.q
      return {line1.q.clone, line1.q.clone}
    end

    p1 = line1.p
    p2 = line2.p
    d1 = line1.direction
    d2 = line2.direction
    n = d1.cross(d2)
    n1 = d1.cross(n)
    n2 = d2.cross(n)

    # the nearest point c₁ of line 1 to line 2 is given by:
    #            (p₂ - p₁) • n₂
    # c₁ = p₁ + ──────────────── d₁
    #                d₁ • n₂
    c1 : Vec3 = (
      p1 + d1 * (
        (p2 - p1).dot(n2) / 
        d1.dot(n2)
      )
    )

    # the nearest point c₂ of line 2 to line 1 is given by:
    #            (p₁ - p₂) • n₁
    # c₂ = p₂ + ──────────────── d₂
    #                d₂ • n₁
    c2 : Vec3 = (
      p2 + d2 * (
        (p1 - p2).dot(n1) /
        d2.dot(n1)
      ) 
    )

    if (c1 - c2).magnitude < 0.00001 # just floating point things
      return {c1, c1.clone}
    else
      return {c1, c2}
    end
  end

  def intersection(other) : Vec3?
    a, b = nearest_points(other)

    if a == b
      a
    elsif (a - b).magnitude < 0.00001
      (a + b) / 2.0
    else
      nil
    end
  end

  def intersects?(other) : { Bool, Vec3 }
    distance = skew_lines_distance(other)

    puts "   d: #{distance}"
    # first check if lines have an exact intersection point
    # do it by checking if the shortest distance is exactly 0
    if distance == 0f64
      puts "3d lines have exact intersection point"
      c = @q
      d = other.q
      e = @p - @q
      f = other.p - other.q
      g = d - c

      # puts p
      # puts q
      puts f
      puts g
      # puts e
      fg_cross = f.cross(g)
      fe_cross = f.cross(e)

      if fg_cross.magnitude == 0 || fe_cross.magnitude == 0
        puts "lines #{self} and #{other} have no intersection, are they parallel?"
        return false, Vec3.new(0f64, 0f64, 0f64)
      end
      fg_cross.normalize!
      fe_cross.normalize!

      dir_sign = fg_cross == fe_cross ? 1 : -1

      puts f.cross(g)
      puts f.cross(e)
      puts "[#{c}] + [#{e}] * #{dir_sign} * ( #{f.cross(g).magnitude} / #{f.cross(e).magnitude})"
      intersection = c + e * dir_sign * ( f.cross(g).magnitude / f.cross(e).magnitude)
      return true, intersection
    end

    if distance > 0.00001
      return false, Vec3.new(0f64, 0f64, 0f64)
    end

    # try to calculate the approximate intersection point
    x1, x2 = nearest_points(other)

    # if !first_is_done || !second_is_done
    #   return false, Vec3.new(0f64, 0f64, 0f64)
    # end

    intersection = (x1 + x2) / 2f64
    return true, intersection
  end

  def segment_midpoint
    offset = direction * 0.5
    @p + offset
  end

  def direction
    @q - @p
  end

  def to_s(io)
    io << @p << " " << @q
  end

  def to_s_vector
    "#{@p} #{direction}"
  end

  def to_2d
    {@p.to_2d(exclude: :z), @q.to_2d(exclude: :z)}
  end

  def to_2d_vector
    {@p.to_2d(exclude: :z), direction.to_2d(exclude: :z)}
  end
end

def parse(input)
  input.lines.map do |line|
    n = line.split(/[\s@,]+/).map(&.to_f64)
    p = Vec3.new(n[0], n[1], n[2])
    m = 1#00000000000
    vector = Vec3.new(n[3] * m, n[4] * m, n[5] * m)
    q = p + vector

    Line.new(p, q)
  end
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
      lines_intersect, ix, iy = line1.intersects_2d?(line2, exclude: :z)
      if lines_intersect
        if test_area_min <= ix <= test_area_max && test_area_min <= iy <= test_area_max
          v1 = line1.direction
          v2 = line2.direction

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

def part2(lines, boundary_max, max_iterations, use_proportional_iteration : Bool = false)

  
  # p1 = Vec3.new(24.0, 13, 10.0)
  # p2 = p1 + Vec3.new(-3.0, 1.0, 2.0)
  # throw_line = Line.new(p1, p2)
  
  # lines.each_with_index do |l1|
  #   puts "\n\n"
  
  #   intersection = l1.intersection(throw_line)
  #   if intersection.nil?
  #     puts "false @ #{intersection}"
  #   else
  #     puts "true @ #{intersection}"
  #   end
  # end
  
  # sort lines by midpoint (probably good enough), then select, first, last and middle
  # line and iterate through points on lines 1 and 2 until arriving at a "throw" line
  # that intersects all 3
  
  lines = lines.sort { |a, b| a.segment_midpoint <=> b.segment_midpoint }

  # assume number of lines >= 3
  l1 = lines.first
  l2 = lines.last
  l3 = lines[lines.size // 2]

  if use_proportional_iteration
    puts "use proportional"
    throw_line = find_proportional_iteration(l1, l2, l3)
  else
    puts "use full"
    throw_line = find_full_iteration(l1, l2, l3, boundary_max)
  end

  if throw_line.nil?
    raise "oh no! couldn't find an intersection in time"
  end

  # extend the throw line's first point so that
  # it covers any input lines that would intersect
  # before our randomly chosen first line
  puts throw_line
  if throw_line.q.magnitude < throw_line.p.magnitude
    # make sure first point is closer to origin
    throw_line.q, throw_line.p = throw_line.p, throw_line.q
  end
  throw_line.p = throw_line.p - throw_line.direction * max_iterations
  puts throw_line


  lines.each_with_index do |l1|
    intersection = l1.intersection(throw_line)
    if intersection.nil?
      puts "no intersection"
    else
      puts "intersection at #{intersection}, time: #{time_at_position(l1, intersection)}ns"
    end
  end

  i1 = l1.intersection(throw_line)
  i2 = l2.intersection(throw_line)

end

def find_full_iteration(l1, l2, l3, boundary_max) : Line?
  # scan every point between l1 and l2 until the resulting line intersects with l3
  throw_line = l1
  pos1 = l1.p.clone
  vec1 = l1.direction
  vec2 = l2.direction
  found = false
  m_max = Vec3.new(boundary_max, boundary_max, boundary_max).magnitude

  puts "selected lines:\n  #{l1}\n  #{l2}"
  puts "target line:\n  #{l3}"

  range = 0..m_max
  i = 0
  while range.includes?(pos1.magnitude)
    pos2 = l2.p.clone
    # puts "#{i} scanning from l1 (#{l1}) at #{pos1}"
    while range.includes?(pos2.magnitude)
      throw_line = Line.new(pos1, pos2)
      distance = throw_line.skew_lines_distance(l3)
      if distance <= 0.00001
        puts "found #{pos1} <-> #{pos2} intersection with l3"
        found = true
        break
      end
      pos2 = pos2 + vec2
      i += 1
      if i % 10000 == 0
        puts "#{i}:    #{pos1},   #{pos2}   #{distance}"
      end
    end
    break if found
    pos1 = pos1 + vec1
  end

  if found
    return throw_line
  else
    return nil
  end
end

def time_at_position(line, position)
  v = line.direction
  m_step = v.magnitude
  m_intersection = Line.new(line.p, position).direction.magnitude
  (m_intersection / m_step).round.to_i
end

def find_proportional_iteration(l1, l2, l3) : Line?
  # scan points between l1 and l2 until the resulting line intersects with l3,
  # using a PID controller to converge on an intersection without having to
  # iterate through every point
  throw_line = l1
  pos1 = l1.p.clone
  vec1 = l1.direction
  vec2 = l2.direction
  found = false
  i = 0
  j = 0
  next_multiplier = 1

  debug_vec_multiplier = 2000000000f64
  format_divisor = 0.00000000001f64
  format_divisor = 1f64
  format_vec_mult = 1000000000000f64
  pos1 = pos1 + vec1 * (478 * debug_vec_multiplier)
  debug_vec_multiplier = 100000000f64
  pos1 = pos1 + vec1 * (107 * debug_vec_multiplier)
  debug_vec_multiplier = 50000000f64
  pos1 = pos1 + vec1 * (45 * debug_vec_multiplier)
  debug_vec_multiplier = 10000000f64
  pos1 = pos1 + vec1 * (140 * debug_vec_multiplier)
  debug_vec_multiplier = 1000000f64
  pos1 = pos1 + vec1 * (468 * debug_vec_multiplier)
  debug_vec_multiplier = 100000f64
  pos1 = pos1 + vec1 * (436 * debug_vec_multiplier)
  debug_vec_multiplier = 10000f64
  pos1 = pos1 + vec1 * (464 * debug_vec_multiplier)
  debug_vec_multiplier = 1000f64 
  pos1 = pos1 + vec1 * (732 * debug_vec_multiplier)
  debug_vec_multiplier = 100f64
  pos1 = pos1 + vec1 * (753 * debug_vec_multiplier)
  debug_vec_multiplier = 10f64
  pos1 = pos1 + vec1 * (10 * debug_vec_multiplier)
  debug_vec_multiplier = 1f64

  # puts "#{l1.p * format_divisor} #{l1.direction * format_vec_mult}"
  # puts "#{l2.p * format_divisor} #{l2.direction * format_vec_mult}"
  # puts "#{l3.p * format_divisor} #{l3.direction * format_vec_mult}"
  # puts "\n\n"
  records = Array({Float64, Float64}).new

  File.open("temp/pid.dat", "w") do |file|
    1200.times do
      pos2 = l2.p.clone
      # puts "#{i} scanning from l1 (#{l1}) at #{pos1}"
      pid = PidController.new(0.125, 1, 0.5)
      first = true
      prev_distance = 0f64
      min = Float64::MAX
      max = Float64::MIN
      100.times do
        throw_line = Line.new(pos1, pos2)
        distance = throw_line.skew_lines_distance(l3)
        min = Math.min(distance, min)
        max = Math.max(distance, max)
        records << {min, max}
        # file.print "#{i} #{distance}\n"
        file.print "#{throw_line.p}\n#{throw_line.q}\n\n\n"
        if distance <= 0.00001
          puts "found #{pos1} <-> #{pos2} intersection with l3"
          found = true
          break
        end
        i += 1
        # puts "#{i.to_s.rjust(4)}:    #{pos1.to_s.ljust(55)} #{pos2.to_s.ljust(80)}   #{distance.format(decimal_places: 1).rjust(26)}   #{next_multiplier.format(decimal_places: 1).rjust(26)}"
        next_multiplier = pid.update(i, distance, 0f64)
        # pos2 = pos2 + vec2 * -next_multiplier
        pos2 = pos2 + vec2 * debug_vec_multiplier
        first = false
        prev_distance = distance
        if first == false && distance > prev_distance
          break
        end
        # if i % 10000 == 0
        # end
        # put some sort of breaker in here to check if the pid controller is causing
        # oscillations
      end
      puts "#{j} #{pos1} #{min * format_divisor} #{max * format_divisor}"
      j += 1
      break if found
      pos1 = pos1 + vec1 * debug_vec_multiplier
    end
  end

  if found
    return throw_line
  else
    return nil
  end
end

class PidController
  @proportional_gain : Float64
  @integral_gain : Float64
  @derivative_gain : Float64
  @integration_stored : Float64 = 0.0
  @error_last : Float64 = 1


  def initialize(@proportional_gain : Float64, @integral_gain : Float64, @derivative_gain : Float64)
  end

  def update(dt, current, target)
    error = target - current

    p = @proportional_gain * error

    error_rate_of_change = (error - @error_last) / dt
    @error_last = error
    d = @derivative_gain * error_rate_of_change

    @integration_stored = @integration_stored + (error * dt)
    i = @integral_gain * @integration_stored

    # puts "target: #{target}, current: #{current}, p#{p} i#{i} d#{d}"
    p + i + d

  end

end