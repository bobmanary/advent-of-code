require "./vector3d"

alias Vec3 = Vector3d(Float64)

class Line
  property p, q : Vec3
  def initialize(@p : Vec3, @q : Vec3)
  end

  def initialize(components : Array(Float64))
    @p = Vec3.new(components[0], components[1], components[2])
    @q = Vec3.new(components[3], components[4], components[5])
  end

  # get the point of intersections between two lines, ignoring one dimension
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

  # get the closest distance between two non-intersecting, non-parallel lines
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
      # this was copied from another implementation and should never be true,
      # since nearest_points already handles small magnitudes
      (a + b) / 2.0
    else
      nil
    end
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

  def direction_2d
    @q.to_2d(exclude: :z) - @p.to_2d(exclude: :z)
  end
end