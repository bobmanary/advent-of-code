def load_input
  File
  .read('inputs/2019-06.txt')
  .lines
  .map(&:chomp)
  .map { |line| line.split ')' }
end

map = {}

load_input.each do |(parent, child)|
  map[child] ||= {parent: nil, children: [], name: child}
  map[parent] ||= {parent: nil, children: [], name: parent}
  map[parent][:children] << map[child]
  map[child][:parent] = map[parent]
end

count = 0
map.values.each do |object|
  loop do
    parent = object[:parent]
    break if parent.nil?
    count += 1
    object = parent
  end
end
puts "total things: #{count}"

path = []
start = map['YOU'][:parent]
destination = map['SAN']

def travel(from, current, path, destination)
  # puts current[:name]
  if current[:parent] == destination || current[:children].include?(destination)
    path << current
    return true
  else
    ([current[:parent]] + current[:children] - [from]).each do |node|
      if node && travel(current, node, path, destination)
        path << current
        return true
      end
    end
  end
  false
end

travel(start, start, path, destination)

puts '--'
puts path.size - 1