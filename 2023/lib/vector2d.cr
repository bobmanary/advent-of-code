class Vector2d(T)
  property x, y : T
  def_hash @x, @y

  def initialize(@x : T, @y : T)
  end

  def +(other)
    Vector2d(T).new(
      @x + other.x,
      @y + other.y
    )
  end

  def add_if_bounded_by(bounding_corner : Vector2d(T), other : Vector2d(T)) : Vector2d(T) | Nil
    new_x = @x + other.x
    new_y = @y + other.y
    if new_x >= 0 && new_y >= 0 && new_x <= bounding_corner.x && new_y <= bounding_corner.y
      Vector2d(T).new(new_x, new_y)
    else
      nil
    end
  end

  def ==(other)
    @x == other.x && @y == other.y
  end

  def clone
    Vector2d(T).new(@x, @y)
  end

  def to_s(io)
    io << @x << ", " << @y
  end
end
