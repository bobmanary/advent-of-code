["inputs/19_example.txt",].each do |filename| # "inputs/19.txt"
  workflows, parts = parse(filename)

  puts "#{filename} part 1: #{part1(workflows, parts)}"

  p2 = part2(workflows)
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

class Rule
  getter destination, is_final

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

  def allowed_range : Hash(Char, Range())
    raise "oh no" if @is_final
    ranges = {'x' => 1..4000, 'm' => 1..4000, 'a' => 1..4000, 's' => 1..4000}
    if @operation == '<'
      ranges[@parameter] = 1..(@value-1)
    else
      ranges[@parameter] = (@value+1)..4000
    end
    ranges
  end

  def final?
    @is_final
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

  def evaluate_rule_ranges
    @rules.each do |rule|
      break if rule.final?
      range = rule.allowed_range
    end
  end
end

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
  
end
