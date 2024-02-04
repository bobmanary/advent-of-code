require "./lib/gnuplot"

module PlottingExtras
  def self.fit_line(samples, centroid, normalized_direction)
    samples_file = File.tempfile("24_samples", ".dat")
    samples.each do |point|
      samples_file.print("#{point}\n")
    end
    samples_file.flush
    centroid_file = File.tempfile("24_centroid", ".dat")
    centroid_file.print("#{centroid}\n")
    centroid_file.flush
    line_file = File.tempfile("24_fitline2", ".dat")
    line_file.print("#{centroid}\n#{centroid + normalized_direction * 350000000000000.0}\n\n")
    line_file.print("#{centroid}\n#{centroid - normalized_direction * 350000000000000.0}\n\n")
    line_file.flush
    plotter = Gnuplot::Control.new(<<-PLOT)
      set term qt 0
      splot '#{centroid_file.path}' with points, \\
      '#{samples_file.path}' with points, \\
      '#{line_file.path}' with linespoints linewidth 2

    PLOT

    puts "Press enter to continue"
    STDIN.gets
    centroid_file.delete
    line_file.delete
    samples_file.delete
    plotter.close
  end
end
