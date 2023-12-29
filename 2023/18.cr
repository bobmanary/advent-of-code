require "./lib/asciimage"

["inputs/18_example.txt", "inputs/18.txt"].each do |filename|
  dig_plan = parse(filename)

  part1 = plot(dig_plan.map {|x| {x[0], x[1]}})
  puts "#{filename} part 1: #{part1}"

  # part2 = plot(dig_plan.map {|x| {x[2], x[3]}})
  # puts "#{filename} part 2: #{part2}"
end

def parse(filename)
  File.read(filename).lines.map do |line|
    line.match(/(\w) (\d+) \(#(\w{5})(\w)\)/)
    second_direction = case $~[4]
      when "0" then 'R'
      when "1" then 'D'
      when "2" then 'L'
      when "3" then 'U'
      else
        raise "Bad second direction #{$~[4]}"
    end
    {$~[1].chars[0], $~[2].to_i, second_direction, $~[3].to_i(16)}
  end
end

def max(a, b)
  a > b ? a : b
end

def min(a, b)
  a < b ? a : b
end

def plot(dig_plan)
  max_x = 1
  max_y = 1
  x = 0
  y = 0
  offset_x = 0
  offset_y = 0
  dug_cells = [{0,0}]

  dig_plan.each do |(direction, steps)|
    steps.times do |i|
      if direction == 'R'
        x += 1
      elsif direction == 'L'
        x -= 1
      elsif direction == 'U'
        y -= 1
      elsif direction == 'D'
        y += 1
        max_y = max(max_y, y+1)
      end
      dug_cells << {x, y}
    end
    max_x = max(max_x, x+1)
    max_y = max(max_y, y+1)
    offset_x = min(offset_x, x)
    offset_y = min(offset_y, y)
  end
  offset_x = offset_x.abs
  offset_y = offset_y.abs
  width = offset_x + max_x
  height = offset_y + max_y
  image = Asciimage.new(width, height)

  image.plot(offset_x, offset_y, '#')
  dug_cells.each do |(x, y)|
    image.plot(x + offset_x, y + offset_y, '#')
  end
  # image.render(flip: true)

  # find a point inside the path
  found_x = found_y = 0
  found_inside = false
  height.times do |i|
    line = image[i]
    offset = line.index('#')
    next if offset.nil?
    found_x = offset+1
    found_y = y+1
    if image[found_y][found_x] == ' '
      found_inside = true
      break
    end
  end

  unless found_inside
    raise "couldn't find a position inside the path"
  end

  image.flood_fill(found_x, found_y, ' ', '#')
  # puts "\n\n"
  # image.render(flip: true)
  image.matrix.array.count('#')
end
