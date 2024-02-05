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

  # assume number of lines >= 3
  # midpoint = lines.size // 2
  # l1 = lines[midpoint - 1]
  # l2 = lines[midpoint + 1]
  # l3 = lines[midpoint]

  if use_proportional
    l1 = potential_lines.last
    l2 = opposite_lines[l1].first
    l3 = perpendicular_lines[l1].first
    l4 = perpendicular_lines[l1].last
    l5 = opposite_lines[l1].last
    throw_line = find_proportional(l1, l2, l3, l4, l5, lines)
  else
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
  puts throw_line
  if throw_line.q.magnitude < throw_line.p.magnitude
    # make sure first point is closer to origin
    throw_line.q, throw_line.p = throw_line.p, throw_line.q
  end
  vec = throw_line.direction
  throw_line.p = throw_line.p - vec
  throw_line.q = throw_line.q + vec
  puts throw_line

  intersections = Hash(Line, Vec3).new
  no_intersections = 0
  lines.each_with_index do |l1|
    intersection = l1.intersection(throw_line)
    if intersection.nil?
      np1, np2 = l1.nearest_points(throw_line) # wasteful, intersection also calls this
      dist = (np2 - np1).magnitude
      # skew line distance and nearest points magnitude return different values
      # due to floating point shenanigans. check both
      if np1 == np2 || dist < 0.1 || l1.skew_lines_distance(throw_line) < 0.1
        intersections[l1] = np2
        # puts "? found a close match at #{np2} (#{dist} or #{dist2})"
        # puts "     with line: #{l1}"
      else
        no_intersections += 1
        # puts "-  #{dist}, #{dist2}"
      end
    else
      intersections[l1] = intersection
      # puts "! intersection at #{intersection}, time: #{time_at_position(l1, intersection)}ns"
      # puts "    line: #{l1}"
    end
  end

  if no_intersections > 0
    puts "#{no_intersections} lines did not have an intersection, try again?"
    exit 1
  end

  lines = lines.sort_by { |line| time_at_position(line, intersections[line]) }

  puts "---"
  l1 = lines[0]
  l2 = lines[1]
  time_interval = time_at_position(l2, intersections[l2]) - time_at_position(l1, intersections[l1])
  distance = (intersections[l2] - intersections[l1]).magnitude
  speed = distance / time_interval
  puts "speed: #{speed}"

  vector = (throw_line.direction.normalize * speed).snap_to_integer!
  puts "direction: #{vector}"

  initial_position = intersections[l1] - vector * time_at_position(l1, intersections[l1]).to_f64
  puts "initial position: #{initial_position} (#{time_at_position(l1, intersections[l1])}ns)"
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
  (m_intersection / m_step).round.to_i64
end

def find_interactively(lines, l1, l2, l3, l4) : Line?
  # use a gnuplot/terminal-based interactive method of finding a matching line

  i = 0
  j = 0
  next_multiplier = 1

  lines = lines - [l1, l2, l3]

  throw_line, distance, offset1, offset2 = interactive_intersection_finder(lines, l1, l2, l3, l4)
  tl_dir = throw_line.direction
  throw_line.p = throw_line.p - tl_dir
  throw_line.q = throw_line.q + tl_dir
  pos1 = l1.p + l1.direction * offset1.to_f64
  pos2 = l2.p + l2.direction * offset2.to_f64

  puts <<-MSG

  Interactive method found #{throw_line}
                           #{pos1} #{pos2}
  Distance: #{distance} units

  Beginning iterative search for exact match...

  MSG

  all_vec_file, target_vec_file = create_vector_files(lines, l1, l2, l3)
  throw_line_file = File.tempfile("24_throw_line", ".dat")
  fit_line_file = File.tempfile("24_fit_line", ".dat")

  write_throw_line(throw_line, throw_line_file)

  gnuplot = get_plotter(all_vec_file, target_vec_file, throw_line_file, fit_line_file)



  throw_line.p = pos1
  throw_line.q = pos2
  refined_line = throw_line
  vec1 = l1.direction
  vec2 = l2.direction
  pos1 = throw_line.p
  pos2 = throw_line.q
  rmin = -40000
  rmax = 40000
  dist2 = 0f64
  gmin = Float64::MAX
  matches = [] of Line
  # found a line! (0.0) - i 9604, j 31363
  (rmin..rmax).each do |i|
  # (-2866..-2866).each do |i|
    min_dist = Float64::MAX
    pos1b = pos1 + vec1 * i.to_f
    (rmin..rmax).each do |j|
    # (-9359..-9359).each do |j|
      pos2b = pos2 + vec2 * j.to_f
      refined_line = Line.new(pos1b, pos2b)
      dist2 = refined_line.skew_lines_distance(l3)
      if dist2 < 0.00001
        puts "!  found a line! (#{dist2}) - i #{i}, j #{j}"
        rl_dir = refined_line.direction
        refined_line.q = refined_line.q + rl_dir
        refined_line.p = refined_line.p - rl_dir
        write_throw_line(refined_line, throw_line_file, truncate: false)
        gnuplot.replot
        exact = 0
        close = 0
        distance_sum = 0f64

        lines.each do |other|
          distance = refined_line.skew_lines_distance(other)
          distance_sum += distance
          int = refined_line.intersection(other)
          if !int.nil?
            exact += 1
          elsif distance < 1.0
            close += 1
          end
        end
        puts "   (exact intersections: #{exact}, close: #{close}, average distance: #{distance_sum / lines.size})"
        matches << refined_line
        # return refined_line
      end
      min_dist = Math.min(dist2, min_dist)
    end
    gmin = min_dist if min_dist < gmin
    puts "   #{min_dist}  #{gmin}  (#{i})" if i % 250 == 0 || min_dist < 0.02
  end

  all_vec_file.delete
  target_vec_file.delete
  throw_line_file.delete
  fit_line_file.delete

  puts "\nall matching lines:"
  matches.each_with_index do |line, i|
    puts "#{i}: #{line}"
  end
  puts "\npick a line by index:"
  match_id = STDIN.gets.as(String)
  gnuplot.close
  return matches[match_id.chomp.to_i]
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

def interactive_intersection_finder(lines, l1, l2, l3, l4)
  puts <<-HELP
  GNUPLOT INTERACTIVE LINE INTERSECTION FINDER
  Uses Gnuplot to visualize line intersections in 3D.
  Press a/e to move pos1 along line1 or pos2 along line2.
  Press w to increase the magnitude of point movements along their respective line, and s to decrease.
  Press spacebar to swap between lines.
  A new line will be drawn between pos1 and pos2, projecting out towards line 3.
  Try to make the new line intersect with line 3.
  Hit enter when you're satisfied with how close the lines are. 
  Try to shoot for a distance close to 1 (or smaller!).
  HELP

  pos1 = l1.p.clone
  pos2 = l2.p.clone
  # pos1 = Vec3.new(343687771508360f64, 289992578065459f64, 319549392507162f64) # found via gnuplot method
  # pos2 = Vec3.new(236645926609322f64, 253593827042829f64, 190995920643689f64)
  throw_line = Line.new(pos1.clone, pos2.clone)
  fitted_line = fit_line(lines, show_plot: true)
  vec1 = l1.direction
  vec2 = l2.direction
  found = false

  all_vec_file, target_vec_file = create_vector_files(lines, l1, l2, l3)
  throw_line_file = File.tempfile("24_throw_line", ".dat")
  fit_line_file = File.tempfile("24_fit_line", ".dat")

  write_throw_line(throw_line, throw_line_file)
  write_throw_line(fitted_line, fit_line_file)

  gnuplot = get_plotter(all_vec_file, target_vec_file, throw_line_file, fit_line_file)

  positions =         [pos1, pos2]
  offsets =           [738973779950u64, 218999979956u64] #[0u64, 0u64] # 
  initial_positions = [pos1, pos2]
  vectors =           [vec1, vec2]
  distance1 = throw_line.skew_lines_distance(l3)
  distance2 = average_distance(throw_line, lines)
  active_pos = 0 # or 1
  magnitude = 1000000000u64
  should_exit = false
  input = InputLoop.new
  input.on(InputLoop::EventType::Enter) { should_exit = true }
  input.on(InputLoop::EventType::Space) { active_pos = active_pos == 0 ? 1 : 0 }
  input.on(InputLoop::EventType::Up) { magnitude = min(100000000000000u64, magnitude * 10) }
  input.on(InputLoop::EventType::Down) { magnitude = max(1u64, magnitude // 10) }
  input.on(InputLoop::EventType::Right) do
    line_offset = offsets[active_pos]
    line_offset += magnitude if UInt64::MAX - magnitude >= line_offset
    position = initial_positions[active_pos] + vectors[active_pos] * line_offset.to_f64
    positions[active_pos] = position
    offsets[active_pos] = line_offset
    # positions[active_pos] = positions[active_pos] + vectors[active_pos] * magnitude.to_f64
  end
  input.on(InputLoop::EventType::Left) do
    line_offset = offsets[active_pos]
    if magnitude <= line_offset
      line_offset -= magnitude 
    else
      line_offset = 0u64
    end
    position = initial_positions[active_pos] + vectors[active_pos] * line_offset.to_f64
    positions[active_pos] = position
    offsets[active_pos] = line_offset
    # positions[active_pos] = positions[active_pos] - vectors[active_pos] * magnitude.to_f64
  end

  input.loop do
    if should_exit
      throw_line_file.delete
      fit_line_file.delete
      all_vec_file.delete
      target_vec_file.delete
      gnuplot.close
      return throw_line, distance1, offsets[0], offsets[1]
    end
    throw_line = Line.new(positions[0], positions[1])
    distance1 = throw_line.skew_lines_distance(l3)
    distance2 = average_distance(throw_line, lines)
    write_throw_line(throw_line, throw_line_file)
    puts <<-STATUS
    Status:
      active: pos#{active_pos}
      pos1: #{positions[0]}
      pos2: #{positions[1]}
      offsets: #{offsets[0]} #{offsets[1]}
      distance1: #{distance1}
      avg:       #{distance2}
      multiplier: #{magnitude}
    STATUS
    gnuplot.replot
  end
end

def fit_line(lines, show_plot : Bool)
  # find a new line that approximately intersects the provided lines/vectors
  # inspired by https://zalo.github.io/blog/line-fitting/
  # (https://zalo.github.io/assets/js/LineFitting/LineFitting.js)

  line_closest_points = [] of Vec3

  # sample points along each line to find an average center point to use
  # as an initial 
  outer_iterations = 11
  samples_per_line = 10
  approx_line = Line.new(Vec3.zero, Vec3.zero)
  distance_multiplier = 100000000000f64

  outer_iterations.times do |i|
    offset_from_start = line_closest_points.empty?
    samples = [] of Vec3
    centroid = Vec3.zero
    distance_multiplier = (10f64 ** (outer_iterations-i)) # decrease by an order of magnitude each iteration
    # distance_multiplier = distance_multiplier * 0.85 # decrease by 40% each iteration
    puts distance_multiplier
    lines.each_with_index do |line, j|
      midpoint_distance = offset_from_start ? 0f64 : (line_closest_points[j] - line.p).magnitude
      magnitude = line.direction.magnitude
      vec = line.direction
      distance_between_samples = 1f64 * distance_multiplier # reduce as the outer loop progresses
      puts " #{distance_between_samples}" if j == 0
      samples_per_line.times do |k|
        scalar = if offset_from_start
          k * distance_between_samples # should allow most hailstones to cross their point of intersection
        else
          (midpoint_distance - ((k - (samples_per_line//2)) * distance_between_samples)) / magnitude
        end
        sample = (line.p + (vec * scalar) )
        samples << sample
        centroid = centroid + sample # this will get quite large
      end
    end
    centroid = centroid * (1.0 / samples.size) # haven't implemented vector division :|

    # figure out a line
    normalized_direction = Vec3.new(1.0, 0.0, 0.0)
    next_direction = Vec3.zero
    samples.each do |point|
      centered_point = point - centroid
      next_direction = next_direction + centered_point * centered_point.dot(normalized_direction)
    end
    normalized_direction = next_direction.normalize
    approx_line = Line.new(centroid - normalized_direction * 250000000000000.0, centroid + normalized_direction * 70000000000000.0)
    line_closest_points = lines.map {|line| line.nearest_points(approx_line)[0]}

    puts "average distance for line fitting: #{average_distance(approx_line, lines)}"
    PlottingExtras.fit_line(samples, centroid, normalized_direction) if show_plot
  
  end
  approx_line
end

def average_distance(new_line, lines)
  sum = 0f64
  lines.each do |line|
    sum += new_line.skew_lines_distance(line)
  end
  sum / lines.size
end

def skew_lines_distance_alt(line1, line2)
  p1, p2 = line1.nearest_points(line2)
  (p1 - p2).magnitude
end

def multi_line_distance(distance1, distance2, line1, line2, line3, line4, line5) : Float64
  line0 = Line.new(
    line1.p + line1.direction.normalize * distance1,
    line2.p + line2.direction.normalize * distance2
  )
  # line0.skew_lines_distance(line3) + line0.skew_lines_distance(line4) + line0.skew_lines_distance(line5)
  skew_lines_distance_alt(line0, line3) + skew_lines_distance_alt(line0, line4) + skew_lines_distance_alt(line0, line5)
end

def find_proportional(line1, line2, line3, line4, line5, lines)
  d1 = 1f64 # some distance down line1, starting at line1.p
  d2 = 1f64
  target = 0.001
  proportion = 0.95
  error = multi_line_distance(d1, d2, line1, line2, line3, line4, line5)
  prev_error = Float64::MAX
  subtract = false
  e1_chain = e2_chain = no_change_chain = 0

  # all_vec_file, target_vec_file = create_vector_files(lines, line1, line2, line3, line4)
  # throw_line_file = File.tempfile("24_throw_line", ".dat")
  # fit_line_file = File.tempfile("24_fit_line", ".dat")

  # write_throw_line(Line.new(
  #   line1.p + line1.direction.normalize * d1,
  #   line2.p + line2.direction.normalize * d2
  # ), throw_line_file)

  # gnuplot = get_plotter(all_vec_file, target_vec_file, throw_line_file, fit_line_file)

  sleep 2
  while error > target
    proportional_adjustment = error * proportion
    # puts "#{error.round(6).to_s.rjust(20)} #{d1.round(4).to_s.rjust(20)} #{d2.round(4).to_s.rjust(20)} #{(error - prev_error).round(4).to_s.rjust(20)} #{proportional_adjustment.round(4).to_s.rjust(20)} #{e1_chain},#{e2_chain}"

    adjusted_d1 = clamp(subtract ? d1 - proportional_adjustment : d1 + proportional_adjustment)
    adjusted_d2 = clamp(subtract ? d2 - proportional_adjustment : d2 + proportional_adjustment)
    # if no_change_chain > 5
    #   puts "reset"
    #   no_change_chain = 0
    #   adjusted_d1 = adjusted_d1 * (1 - (rand * 0.00000001))
    #   adjusted_d2 = adjusted_d2 * (1 - (rand * 0.00000001))
    # end
    e1 = multi_line_distance(adjusted_d1, d2, line1, line2, line3, line4, line5)
    e2 = multi_line_distance(d1, adjusted_d2, line1, line2, line3, line4, line5)

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

    # write_throw_line(Line.new(
    #   line1.p + line1.direction.normalize * d1,
    #   line2.p + line2.direction.normalize * d2
    # ), throw_line_file)
    # gnuplot.replot

    # sleep 0.033
  end

  p1 = line1.p + line1.direction.normalize * d1
  p2 = line2.p + line2.direction.normalize * d2
  p1.x = p1.x.round
  p1.y = p1.y.round
  p1.z = p1.z.round
  p2.x = p2.x.round
  p2.y = p2.y.round
  p2.z = p2.z.round
  Line.new(p1, p2)
end

def clamp(n)
  n < 0f64 ? 0f64 : n
end

def round(n)
  n.round
end
