require "./vector2d"

class Vector3d(T)
  property x, y, z : T
  def_hash @x, @y, @z

  def initialize(@x : T, @y : T, @z : T)
  end

  def +(other)
    Vector3d(T).new(
      @x + other.x,
      @y + other.y,
      @z + other.z
    )
  end

  def ==(other)
    @x == other.x && @y == other.y && @z == other.z
  end

  def clone
    Vector3d(T).new(@x, @y, @z)
  end

  def to_s(io)
    io << @x << ", " << @y << ", " << @z
  end

  def to_2d(exclude : Symbol)
    axes = case exclude
      when :x then {@y, @z}
      when :y then {@x, @z}
      when :z then {@x, @y}
      else raise "exclude must be :x, :y or :z"
    end

    Vector2d(T).new(axes[0], axes[1])
  end
end
