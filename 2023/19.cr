require "benchmark"

alias XmasRangeHash = Hash(Char, Range(UInt16, UInt16))

["inputs/19_example.txt", "inputs/19.txt"].each do |filename| #

  workflows, parts = parse(filename)
  p1 = 0u32
  p2 = 0u64
  Benchmark.ips do |x|
    x.report("#{filename} parse") do
      parse(filename)
    end
    x.report("#{filename} part 1") do
      p1 = part1(workflows, parts)
    end
    x.report("#{filename} part 2") do
      p2 = part2(workflows)
    end
  end
  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end


def parse(filename)
  workflows = Hash(String, Workflow).new
  parts = Array(Part).new
  parsing_workflows = true

  File.open(filename) do |f|
    while line = f.gets('\n', 100, true)
      if line.size == 0
        parsing_workflows = false
        next
      end
      if parsing_workflows
        workflow = parse_workflow(line)
        workflows[workflow.id] = workflow
      else
        parts << parse_part(line)
      end
    end
  end

  return workflows, parts
end

def parse_workflow(line)
  id, _, rules_s = line.partition('{')
  rules = [] of Rule
  rules_s.rchop.split(',') do |rule_s|
    if rule_s.includes?(':')
      parameter = rule_s.char_at(0)
      operation = rule_s.char_at(1)
      value_s, _, destination = rule_s[2..].partition(':')
      rules << Rule.new(parameter, operation, value_s.to_u16, destination)
    else
      rules << Rule.new(' ', ' ', 0u16, rule_s, true)
    end
  end
  Workflow.new(id, rules)
end

def parse_part(line)
  line = line[1..line.size-2]
  params = [] of UInt16
  line.split(',') do |param|
    params << param[2..].to_u16
  end

  Part.new(params[0], params[1], params[2], params[3])
end

class Part
  getter x, m, a, s
  def initialize(@x : UInt16, @m : UInt16, @a : UInt16, @s : UInt16)
  end

  def sum
    @x + @m + @a + @s
  end
end



def merge_range(source, other)
  new_hash = XmasRangeHash.new
  source.each do |xmas_char, source_range|
    overlapping_range = range_overlap(source_range, other[xmas_char])
    if overlapping_range.nil?
      puts source
      puts other
      raise "wtf"
    end
    new_hash[xmas_char] = overlapping_range
  end

  new_hash
end

def merge_ranges(source, others) : Array(XmasRangeHash)
  others.clone.each do |other|
    other.each do |xmas_char, other_range|
      overlap = range_overlap(source[xmas_char], other_range)
      next if overlap.nil?
      other[xmas_char] = overlap
    end
  end

  others
end

def range_overlap(a, b) : Range(UInt16, UInt16) | Nil
  return nil if a.nil? || b.nil?
  b, a = a, b if a.begin > b.begin
  
  if b.end >= a.begin && b.begin <= a.end
    Math.max(a.begin, b.begin)..Math.min(a.end, b.end)
  else
    nil
  end
end

class Rule
  getter destination, is_final, parameter, operation, value

  def initialize(@parameter : Char, @operation : Char, @value : UInt16, @destination : String, @is_final : Bool = false)
  end

  def apply(part : Part)
    return true if @is_final
    part_value = case @parameter
      when 'x' then part.x
      when 'm' then part.m
      when 'a' then part.a
      when 's' then part.s
      else raise "Wat"
    end

    if @operation == '<'
      part_value < @value
    else
      part_value > @value
    end
  end

  def allowed_range(cumulative_range) : {XmasRangeHash | Nil, XmasRangeHash | Nil}
    left = cumulative_range.clone
    right = cumulative_range.clone
    if @operation == '<'
      lro = range_overlap(cumulative_range[@parameter], 1u16..(@value-1))
      rro = range_overlap(cumulative_range[@parameter], (@value)..4000u16)
    else
      lro = range_overlap(cumulative_range[@parameter], (@value+1)..4000u16)
      rro = range_overlap(cumulative_range[@parameter], 1u16..@value)
    end
    if lro.nil?
      left = nil
    else
      left[@parameter] = lro
    end
    if rro.nil?
      right = nil
    else
      right[@parameter] = rro
    end

    return {left, right}
  end

  def final?
    @is_final
  end

  def self.default_range_hash : XmasRangeHash
    {'x' => 1u16..4000u16, 'm' => 1u16..4000u16, 'a' => 1u16..4000u16, 's' => 1u16..4000u16}
  end

  def to_s(io)
    if @is_final
      io << @destination
    else
      io << @parameter << @operation << @value << ':' << @destination
    end
  end
end

class Workflow
  getter id
  def initialize(@id : String, @rules : Array(Rule))
  end

  def process_rules(part : Part)
    @rules.each do |rule|
      if rule.apply(part)
        return rule.destination
      end
    end

    raise "invalid final rule for #{@id}"
  end

  def evaluate_rule_ranges(all_workflows, cumulative_range : XmasRangeHash, depth)
    ranges = [] of XmasRangeHash
    @rules.each do |rule|
      if rule.destination == "R" && rule.final?
        break
      elsif rule.destination == "A" && rule.final?
        ranges << cumulative_range.clone
        break
      elsif rule.destination == "R"
        left, right = rule.allowed_range(cumulative_range)
        break if right.nil?
        # "true" path ended, let iteration handle "false" path
        cumulative_range = right
      elsif rule.final?
        # hit a non-A/R final rule, evaluate the next workflow
        next_workflow = all_workflows[rule.destination]
        ranges.concat next_workflow.evaluate_rule_ranges(all_workflows, cumulative_range, depth + 1)
      else
        left, right = rule.allowed_range(cumulative_range)

        if rule.destination == "A" && !left.nil?
          # hit an accept before the last rule
          ranges << left
        elsif !left.nil?
          # go down "true" path
          next_workflow = all_workflows[rule.destination]
          ranges.concat next_workflow.evaluate_rule_ranges(all_workflows, left, depth + 1)
        end

        # let iteration handle "false" path
        break if right.nil?
        cumulative_range = right
      end

    end
    ranges
  end
end
# in s<1351 -> px a<2006 -> qkq x<1416 -> A                      x: 1..1415,    m: 1..4000,    a: 1..2005,    s: 1..1350
#                                      -> crn x>2662 -> A        x: 2663..4000, m: 1..4000,    a: 1..2005,    s: 1..1350
#           -> px m>2090 -> A                                    x: 1..4000,    m: 2091..4000, a: 2006..4000, s: 1..1350
# in (s >= 1351) -> qqz (s <= 2770 && m<1801) -> hdj m>838 -> A  x:1..4000,     m:839..1800,   a:1..4000,     s:1351..2770

def process_workflows(workflows, part)
  workflow_id = "in"
  while workflow = workflows[workflow_id]
    workflow_id = workflow.process_rules(part)
    if workflow_id == "A"
      return part.sum
    elsif workflow_id == "R"
      return 0u32
    end
  end
  0u32
end

def part1(workflows, parts)
  accepted = 0u32
  parts.each do |part|
    accepted += process_workflows(workflows, part)
  end

  accepted
end

def part2(workflows)
  xmas_ranges = workflows["in"].evaluate_rule_ranges(workflows,Rule.default_range_hash, 0)
  sum = 0u64
  xmas_ranges.each do |range|
    # print "x: #{range['x']}".ljust(15)
    # print "m: #{range['m']}".ljust(15)
    # print "a: #{range['a']}".ljust(15)
    # print "s: #{range['s']}".ljust(15)
    # print "\n"
    sum += range.values.map(&.size).reduce(1u64) { |acc, size| acc * size }
  end
  sum
end
