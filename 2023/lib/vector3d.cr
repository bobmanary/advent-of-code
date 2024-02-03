require "./vector2d"

class Vector3d(T)
  property x, y, z : T
  def_hash @x, @y, @z

  def initialize(@x : T, @y : T, @z : T)
  end

  def self.zero
    new(0.0, 0.0, 0.0)
  end

  def +(other)
    Vector3d(T).new(
      @x + other.x,
      @y + other.y,
      @z + other.z
    )
  end

  def -(other)
    Vector3d(T).new(
      @x - other.x,
      @y - other.y,
      @z - other.z
    )
  end

  def ==(other)
    @x == other.x && @y == other.y && @z == other.z
  end

  def *(magnitude : Float32)
    Vector3d(T).new(@x * magnitude, @y * magnitude, @z * magnitude)
  end

  def *(magnitude : Float64)
    Vector3d(T).new(@x * magnitude, @y * magnitude, @z * magnitude)
  end

  def /(rhs : Float64)
    Vector3d(T).new(@x / rhs, @y / rhs, @z / rhs)
  end

  def length_squared
    m = magnitude
    m * m
  end

  def clone
    Vector3d(T).new(@x, @y, @z)
  end

  def to_s(io)
    io << @x << " " << @y << " " << @z
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

  def dot(other)
    @x * other.x + @y * other.y + @z * other.z
  end

  def cross(other : Vector3d(T))
    Vector3d(T).new(
      @y * other.z - @z * other.y,
      @z * other.x - @x * other.z,
      @x * other.y - @y * other.x
    )
  end

  def magnitude : Float64
    Math.sqrt(dot(self))
  end

  def normalize : Vector3d(Float64)
    Vector3d(Float64).new(@x, @y, @z).normalize!
  end

  def <=>(b)
    self.magnitude <=> b.magnitude
  end

  def normalize!
    m = magnitude
    @x /= m
    @y /= m
    @z /= m
    self
  end

  def values
    [@x, @y, @z]
  end

  def angle(other)
    m_a = magnitude
    m_b = other.magnitude
    radians = Math.acos(dot(other) / (m_a * m_b))
    radians * (180/Math::PI)
  end
end
