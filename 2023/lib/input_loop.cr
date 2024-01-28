class InputLoop
  enum EventType
    Up
    Right
    Down
    Left
    Quit
    Space
    Enter
    None
  end

  @events : Hash(EventType, Array(Proc(Nil)))
  def initialize
    @events = Hash(EventType, Array(Proc(Nil))).new
  end

  def on(event, &block)
    if !@events.has_key?(event)
      @events[event] = Array(Proc(Nil)).new
    end
    @events[event] << block
  end

  # Begin processing keyboard input and triggering event
  # callbacks.
  # If a registered event is handled, the block provided
  # to #loop will be called after callbacks are processed.
  def loop(&block)
    while true
      char = STDIN.raw &.read_char
      type = case char
      when 'w' then EventType::Up
      when 'd' then EventType::Right
      when 's' then EventType::Down
      when 'a' then EventType::Left
      when 'q' then EventType::Quit
      when ' ' then EventType::Space
      when '\r' then EventType::Enter
      else EventType::None
      end

      if @events.has_key?(type)
        @events[type].each &.call
        yield
      end
    end
  end
end
