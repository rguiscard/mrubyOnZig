# ----------------------------------------
# Minimal cooperative scheduler
# ----------------------------------------
class Scheduler
  def initialize
    @ready = []
    @sleeping = []
    @time = 0.0
  end

  def spawn(&block)
    @ready << Fiber.new { block.call }
  end

  def sleep(seconds)
    Fiber.yield [:sleep, @time + seconds]
  end

  def run
    loop do
      # wake sleeping fibers
      @sleeping.delete_if do |f, wake|
        if wake <= @time
          @ready << f
          true
        else
          false
        end
      end

      break if @ready.empty? && @sleeping.empty?

      if @ready.empty?
        # advance logical time
        @time = @sleeping.map { |_, t| t }.min
        next
      end

      f = @ready.shift
      ev = f.resume

      if f.alive? && ev && ev[0] == :sleep
        @sleeping << [f, ev[1]]
      end
    end
  end
end

@@count = 0

# ----------------------------------------
# Fake ping implementation
# ----------------------------------------
def fake_ping(ip)
  # Simple deterministic pseudo-randomness
  # (no Random, no srand)
  @seed ||= 1234567
  @seed = (@seed * 1103515245 + 12345) & 0x7fffffff

  # ~70% success rate
  (@seed % 10) < 3
end

# ----------------------------------------
# Continuous ping fiber
# ----------------------------------------
def ping_loop(ip, sched)
  short_sleep = 1.0
  long_sleep  = 5.0

  loop do
    puts "ping #{ip}..."

#    if fake_ping(ip)
    if zig_ping(ip)
      puts "ping #{ip}: success, sleeping #{long_sleep}s"
      sched.sleep(long_sleep)
    else
      puts "ping #{ip}: failed, retry in #{short_sleep}s"
      sched.sleep(short_sleep)
    end
    @@count = @@count + 1
    if @@count > 10
      break
    end
  end
end

# ----------------------------------------
# Main
# ----------------------------------------
sched = Scheduler.new

sched.spawn do
  ping_loop("https://www.google.com", sched)
end

sched.spawn do
  ping_loop("www.google.com", sched)
end

sched.run
