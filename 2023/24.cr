require "./lib/vector3d"
require "./lib/line"
require "./lib/gnuplot"
require "./lib/input_loop"
require "./24_plotting_extras"

[
  {"inputs/24_example.txt", 7f64, 27f64, 10f64, false},
  {"inputs/24.txt", 200000000000000f64, 400000000000000f64, 2600000000000f64, true}
].each do |(filename, test_area_min, test_area_max, max_iterations, use_proportional)|
  input = File.read(filename)
  lines = parse(input)
  puts "#{filename} part 1: #{part1(lines, test_area_min, test_area_max)}"

  p2 = part2(lines, test_area_max, max_iterations, use_proportional)
  puts "#{filename} part 2: #{p2}"
end

def parse(input)
  input.lines.map do |line|
    n = line.split(/[\s@,]+/).map(&.to_f64)
    # I dunno why I decided to do a line segment instead of a ray, but here we are
    p = Vec3.new(n[0], n[1], n[2])
    vector = Vec3.new(n[3], n[4], n[5])
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

def part2(lines, boundary_max, max_iterations, use_proportional : Bool = false)
  opposite_lines = Hash(Line, Array(Line)).new
  perpendicular_lines = Hash(Line, Array(Line)).new
  lines.each_with_index do |line1, i|
    opposite_lines[line1] = [] of Line
    perpendicular_lines[line1] = [] of Line
    lines.each_with_index do |line2, j|
      next if line1 == line2
      angle = line1.direction.angle(line2.direction)
      opposite_lines[line1] << line2 if angle > 170
      perpendicular_lines[line1] << line2 if angle > 39 && angle < 51
    end
  end

  lines = lines.sort_by { |line| opposite_lines[line].try(&.size) || 0 }.reverse

  potential_lines = lines.select { |line| perpendicular_lines[line].size > 1 && opposite_lines[line].size > 1 }

  if use_proportional && lines.size > 5
    # the proportional iteration solution for finding a thrown rock line
    # relies somewhat on a particular relative arrangement of lines in space
    # (just picking the first 5 lines in my input doesn't work for this method)
    l1 = potential_lines.last      # l1 and l2 are used to find a point along each that produces a line
    l2 = opposite_lines[l1].first  # which intersects with l3, l4, and l5
    l3 = perpendicular_lines[l1].first
    l4 = perpendicular_lines[l1].last
    l5 = opposite_lines[l1].last
    throw_line = find_proportional(l1, l2, l3, l4, l5, lines)
  else
    # this only really works for small inputs
    l1 = lines[0]
    l2 = lines[1]
    l3 = lines[2]
    throw_line = find_full_iteration(l1, l2, l3, boundary_max)
  end

  if throw_line.nil?
    raise "oh no! couldn't find an intersection"
  end

  # extend the throw line's first point so that
  # it covers any input lines that would intersect
  # before our randomly chosen first line
  if throw_line.q.magnitude < throw_line.p.magnitude
    # make sure first point is closer to origin
    throw_line.q, throw_line.p = throw_line.p, throw_line.q
  end
  vec = throw_line.direction
  throw_line.p = throw_line.p - vec
  throw_line.q = throw_line.q + vec

  intersections = Hash(Line, Vec3).new
  no_intersections = 0
  lines.each_with_index do |l1|
    intersection = l1.intersection(throw_line)
    if intersection.nil?
      np1, np2 = l1.nearest_points(throw_line) # wasteful, intersection also calls this
      dist = (np2 - np1).magnitude
      # skew_line_distance and magnitude of nearest_points return slightly different values
      # due to floating point shenanigans, so check both
      if np1 == np2 || dist < 0.1 || l1.skew_lines_distance(throw_line) < 0.1
        intersections[l1] = np2
      else
        no_intersections += 1
      end
    else
      intersections[l1] = intersection
    end
  end

  if no_intersections > 0
    puts "#{no_intersections} lines did not have an intersection, oh bother"
    exit 1
  end

  lines = lines.sort_by { |line| time_at_position(line, intersections[line]) }

  l1 = lines[0]
  l2 = lines[1]
  time_interval = time_at_position(l2, intersections[l2]) - time_at_position(l1, intersections[l1])
  distance = (intersections[l2] - intersections[l1]).magnitude
  speed = distance / time_interval

  vector = (throw_line.direction.normalize * speed).snap_to_integer!

  initial_position = intersections[l1] - vector * time_at_position(l1, intersections[l1]).to_f64
  initial_position.x.to_i64 + initial_position.y.to_i64 + initial_position.z.to_i64
end


def find_full_iteration(l1, l2, l3, boundary_max) : Line?
  # scan every point between l1 and l2 until the resulting line intersects with l3
  throw_line = l1
  pos1 = l1.p.clone
  vec1 = l1.direction
  vec2 = l2.direction
  found = false
  m_max = Vec3.new(boundary_max, boundary_max, boundary_max).magnitude

  range = 0..m_max
  i = 0
  while range.includes?(pos1.magnitude)
    pos2 = l2.p.clone
    while range.includes?(pos2.magnitude)
      throw_line = Line.new(pos1, pos2)
      distance = throw_line.skew_lines_distance(l3)
      if distance <= 0.00001
        found = true
        break
      end
      pos2 = pos2 + vec2
      i += 1
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
  (m_intersection / m_step).round.to_i64
end

def create_vector_files(lines, l1, l2, l3, l4 : Line? = nil)
  all_file = File.tempfile("24_allvectors", ".dat")
  lines.each do |line|
    next if line == l1 || line == l2 || line == l3 || (!l4.nil? && line == l4)
    all_file.print "#{line.q} #{line.direction}\n"
  end
  all_file.flush

  target_file = File.tempfile("24_targetvectors", ".dat")

  target_file.print "#{l1.p} #{l1.direction}\n"
  target_file.print "#{l2.p} #{l2.direction}\n"
  target_file.print "#{l3.p} #{l3.direction}\n"
  target_file.print "#{l4.p} #{l4.direction}\n" if !l4.nil?
  target_file.flush
  {all_file, target_file}
end

def write_throw_line(line, file, truncate = true)
  p1 = line.p
  p2 = line.q
  if p1.magnitude > p2.magnitude
    line = Line.new(p2, p1)
  end
  if truncate
    file.rewind
    file.truncate
  end
  file.print "#{line.p}\n#{line.p + line.direction * 2.0}\n\n"
  file.flush
end

def get_plotter(all_vectors_file, target_vectors_file, drawn_line_file, fit_line_file)
  plot_command = <<-PLOT
  set term qt 0
  splot '#{all_vectors_file.path}' using 1:2:3:($4*400000000000):($5*400000000000):($6*400000000000) with vector, \\
  '#{target_vectors_file.path}' using 1:2:3:($4*400000000000):($5*400000000000):($6*400000000000) with vector, \\
  '#{drawn_line_file.path}' with linespoints linewidth 2, \\
  '#{fit_line_file.path}' with linespoints linewidth 2

  PLOT
  Gnuplot::Control.new(plot_command)
end

def max(a : UInt64, b : UInt64) : UInt64
  if a > b
    a
  else
    b
  end
end

def min(a : UInt64, b : UInt64) : UInt64
  if a < b
    a
  else
    b
  end
end

def skew_lines_distance_alt(line1, line2)
  p1, p2 = line1.nearest_points(line2)
  (p1 - p2).magnitude
end

def multi_line_distance(distance1, distance2, line1, line2, line3, line4, line5) : Float64
  potential_new_line = Line.new(
    line1.p + line1.direction.normalize * distance1,
    line2.p + line2.direction.normalize * distance2
  )
  skew_lines_distance_alt(potential_new_line, line3) + skew_lines_distance_alt(potential_new_line, line4) + skew_lines_distance_alt(potential_new_line, line5)
end

# Given five lines, move a point down each of the first two lines,
# line, producing a new line between those points until that new line
# intersects with lines 3, 4, and 5.
# The distance each point is moved per iteration decreases the closer
# the new line is to intersecting.
def find_proportional(line1, line2, line3, line4, line5, lines)
  d1 = 1f64 # some distance down line1, starting at line1.p
  d2 = 1f64
  target = 0.001 # non-zero to account for cumulative floating point error
  proportion = 0.95 # tested to work reasonably well

  # error here is the sum of the distances between (the new line between the
  # points on lines 1 and 2) and (that line's nearest point on lines 3, 4, and 5)
  error = multi_line_distance(d1, d2, line1, line2, line3, line4, line5)

  # ideally, the previous error value would always be larger than the current
  # error value (i.e. each iteration strictly gets closer to zero), but in the
  # real world, proportional control overshoots the target. when that happens,
  # we want to subtract the proportional adjustment from the current point
  # (backtrack closer to the line's origin) rather than moving further away
  # from it.
  subtract = false 

  prev_error = Float64::MAX
  e1_chain = e2_chain = no_change_chain = 0

  while error > target
    proportional_adjustment = error * proportion
    # puts "#{error.round(6).to_s.rjust(20)} #{d1.round(4).to_s.rjust(20)} #{d2.round(4).to_s.rjust(20)} #{(error - prev_error).round(4).to_s.rjust(20)} #{proportional_adjustment.round(4).to_s.rjust(20)} #{e1_chain},#{e2_chain}"

    # move along each line
    adjusted_d1 = clamp(subtract ? d1 - proportional_adjustment : d1 + proportional_adjustment)
    adjusted_d2 = clamp(subtract ? d2 - proportional_adjustment : d2 + proportional_adjustment)
    
    if no_change_chain > 5
      puts "went 5 iterations without changing, jiggling new line slightly (this shouldn't happen)"
      # but might on different inputs?
      no_change_chain = 0
      adjusted_d1 = adjusted_d1 * (1 - (rand * 0.00000001))
      adjusted_d2 = adjusted_d2 * (1 - (rand * 0.00000001))
    end

    # see whether adjusting the point on line 1 or 2 got closer to zero
    # and use the lower one 
    e1 = multi_line_distance(adjusted_d1, d2, line1, line2, line3, line4, line5)
    e2 = multi_line_distance(d1, adjusted_d2, line1, line2, line3, line4, line5)

    # escape hatch in case we got stuck iterating down one line, also shouldn't happen
    if e1 < e2
      e1_chain += 1
    else
      e2_chain += 1
    end

    if (e1 < e2 && e1_chain < 10) || e2_chain >= 10
      d1 = adjusted_d1
      prev_error = error
      error = e1
      e2_chain = 0
    else
      d2 = adjusted_d2
      prev_error = error
      error = e2
      e1_chain = 0
    end

    subtract = error > prev_error
    if error == prev_error
      no_change_chain += 1 
    else
      no_change_chain = 0
    end
  end

  p1 = (line1.p + line1.direction.normalize * d1).snap_to_integer!
  p2 = (line2.p + line2.direction.normalize * d2).snap_to_integer!
  Line.new(p1, p2)
end

def clamp(n)
  n < 0f64 ? 0f64 : n
end
