def bytes_to_layers(data, w, h)
  layers = []
  layer = 0
  offset = 0
  
  while offset < data.size
    if layers[layer].nil?
      layers << []
    end
    layers[layer] << data[offset]
    offset += 1
    if layers[layer].size == w*h
      layer += 1
    end
  end
  layers
end

def load_image
  data = File.read('inputs/08.txt').split('').map &:to_i
end

def load_test_image(data, w, h)
  bytes_to_layers data.split('').map(&:to_i), w, h
end

def part1(image)
  layer_least_zeros = image.reduce(image[0]) do |memo, layer|
    if layer.select {|n| n == 0}.size < memo.select {|n| n == 0}.size
      layer
    else
      memo
    end
  end

  layer_least_zeros
  .group_by(&:to_i)
  .transform_values(&:size)
  .values_at(1, 2)
  .reduce(:*)
end

def part2(image)
  flattened_image = image[0].map { 2 }
  image.reverse.each do |layer|
    layer.each_with_index do |byte, i|
      if byte < 2
        flattened_image[i] = byte
      end
    end
  end
  flattened_image
end

def print_layer(layer, w)
  offset = 0
  puts '░' * w
  while offset < layer.size
    puts layer.slice(offset, w).map {|byte| byte == 1 ? '█' : ' '}.join('')
    offset += w
  end

  puts '░' * w
  return
end

def main
  puts "part 1: #{part1(bytes_to_layers(load_image, 25, 6))}"
  puts "part 2:"
  test_image = load_test_image '0222112222120000', 2, 2
  puts part2 test_image
  print_layer( part2( test_image), 2)
  image = part2(bytes_to_layers(load_image, 25, 6))
  print_layer image, 25
  # image.
end

main()
