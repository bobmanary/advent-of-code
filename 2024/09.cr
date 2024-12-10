["inputs/09_test.txt", "inputs/09.txt"].each do |filename|
  blocks, gaps, files, used_block_count = parse(filename)

  p1 = part1(blocks.clone, gaps.clone, used_block_count)
  p2 = part2(blocks.clone, gaps.clone, files.clone)

  puts "#{filename} part 1: #{p1}"
  puts "#{filename} part 2: #{p2}"
end

class DBlock
  property file : DFile?
  def initialize(@file)
  end

  def empty?
    @file.nil?
  end

  def clone
    DBlock.new(@file.nil? ? nil : @file.clone)
  end
end

class DFile
  property size : Int32
  property id : Int32
  def initialize(@size, @id)
  end
  def empty?
    false
  end
  def clone
    DFile.new(@size, @id)
  end
end

class DGap
  property position : Int32
  property end_position : Int32

  def initialize(@position, @end_position)
  end

  def size
    (@end_position - @position) + 1
  end

  def clone
    DGap.new(@position, @end_position)
  end
end


def parse(filename)
  offset = 0
  file_id = 0
  used_block_count = 0

  blocks = [] of DBlock
  files = [] of DFile
  gaps = Array(DGap).new

  File.read(filename).chars.each_slice(2, reuse: true) do |(file_size, gap_size)|
    fsize = file_size.to_i
    gsize = (gap_size.nil? || gap_size == '\n') ? 0 : gap_size.to_i

    dfile = DFile.new(fsize, file_id)

    fsize.times { blocks << DBlock.new(dfile) }
    gsize.times { blocks << DBlock.new(nil) }

    files << dfile

    gaps << DGap.new(offset + fsize, offset + fsize + gsize - 1) if gsize > 0

    offset += fsize + gsize
    file_id += 1
    used_block_count += fsize
  end

  {blocks, gaps, files, used_block_count}
end

def part1(blocks, gaps, used_block_count)
  gap_index = 0
  used_index = blocks.size - 1
  while used_index > used_block_count
    gap_index = blocks.index(gap_index) {|block| block.empty?}
    used_index = blocks.rindex(used_index) {|block| !block.empty?}
    break if gap_index.nil? || used_index.nil?
    blocks[gap_index].file = blocks[used_index].file
    blocks[used_index].file = nil
  end
  checksum = 0u64
  0.upto(used_block_count - 1) do |i|
    block = blocks[i]
    unless block.file.nil?
      checksum += block.file.as(DFile).id * i
    end
  end

  checksum
end

def part2(blocks, gaps, files)
  files.reverse_each do |file|
    block_position = blocks.index do |block|
      f = block.file
      !f.nil? && f.id == file.id
    end

    raise "???" if block_position.nil?
    gap = gaps.find {|gap| gap.size >= file.size && gap.position < block_position}
    next if gap.nil?

    # update empty blocks to point at moved file
    gap.position.upto(gap.position + file.size - 1) do |i|
      blocks[i].file = file
    end

    # update old blocks to be empty
    block_position.upto(block_position + file.size - 1) do |i|
      blocks[i].file = nil
    end

    if gap.size == file.size
      gaps.delete(gap)
    else
      gap.position += file.size
    end
    old_pos_prev_gap = gaps.find {|g| g.end_position == block_position - 1}
    old_pos_next_gap = gaps.find {|g| g.position == block_position + file.size}
    if old_pos_prev_gap && old_pos_next_gap
      # merge gaps that sandwich original file position
      old_pos_prev_gap.end_position = old_pos_next_gap.end_position
      gaps.delete(old_pos_next_gap)
    elsif old_pos_prev_gap
      # update preceding gap to cover end of original position
      old_pos_prev_gap.end_position = block_position + file.size - 1
    elsif old_pos_next_gap
      # update following gap to cover start of original position
      old_pos_next_gap.position = block_position
    else
      # insert a new gap
      new_gap = DGap.new(block_position, block_position + file.size - 1)
      insertion_point = gaps.rindex {|g| g.position < block_position}
      if insertion_point.nil?
        gaps.unshift(new_gap)
      else
        gaps.insert(insertion_point + 1, new_gap)
      end
    end
  end

  checksum = 0u64
  blocks.each_with_index do |block, i|
    f = block.file
    if !f.nil?
      checksum += f.id * i
    end
  end
  checksum
end

def print_disk_state(blocks)
  line1 = String.build(blocks.size) do |str|
    0.upto(blocks.size - 1) do |i|
      str << i.to_s.chars.last
    end
  end

  line2 = String.build(blocks.size) do |str|
    blocks.each do |block|
      if block.empty?
        str << '.'
      else
        str << block.file.as(DFile).id.to_s.chars.last
      end
    end
  end

  puts "#{line1}\n#{line2}"
end

def print_gap_state(gaps, block_count)
  line = Array(Char).new(block_count, '█')
  gaps.each do |gap|
    gap.position.upto(gap.end_position) do |pos|
      line[pos] = '.' if pos < block_count
    end
  end
  puts line.join("")
end
