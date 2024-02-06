require "./vector2d"
module Gnuplot
  class Vectors(T)
    @lines : Array(Tuple(Vector2d(T), Vector2d(T)))
    @boxes : Array(Tuple(Vector2d(T), Vector2d(T)))

    def initialize
      @lines = Array(Tuple(Vector2d(T), Vector2d(T))).new
      @boxes = Array(Tuple(Vector2d(T), Vector2d(T))).new
    end

    def add(p : Vector2d(T), q : Vector2d(T))
      @lines << {p, q}
    end

    def add(new_lines : Array(Tuple(Vector2d(T), Vector2d(T))))
      @lines.concat new_lines
    end

    def add_box(a : Vector2d(T), b : Vector2d(T))
      @boxes << {a, b}
    end

    def export(filename)
      File.open("#{filename}.dat", "w") do |file|
        @lines.each do |(p, q)|
          file.print "#{p.x} #{p.y} #{q.x} #{q.y}\n\n"
        end
      end

      File.open("#{filename}.plot", "w") do |file|
        @boxes.each do |b|
          file.print <<-STRING
            set style rect fc lt -1 fs solid 0.15 noborder
            set obj rect from #{b[0].x}, #{b[0].y} to #{b[1].x}, #{b[1].y}

          STRING
        end
        file.print <<-STRING
          plot '#{filename}.dat' with vectors filled head lw 2
        STRING
      end
    end
  end

  class Control
    @child_process : Process
    # @command_file : File
    def initialize(command)
      # @command_file = File.tempfile("plot", ".gnu")
      # @command_file.print(command)
      # @command_file.flush
      path = Process.find_executable("gnuplot")
      raise "oh no" unless path.is_a?(String)
      @child_process = Process.new(
        path,
        input: Process::Redirect::Pipe,
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit,
      )
      @child_process.input.print(command)
    end

    def replot
      @child_process.input.print("replot\n")
    end

    def close
      @child_process.input.print("quit\n")
    end
  end
end
