require 'stringio'

# utility methods totally not edited from StackOverflow
class Utils
  # captures stdout from a block: out = capture_stdout { code }
  def self.capture_stdout
    Thread.current[:old_stdout] = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = Thread.current[:old_stdout] if Thread.current[:old_stdout]
    Thread.current[:old_stdout] = nil
  end

  # captures stderr from a block: err = capture_stderr { code }
  def self.capture_stderr
    Thread.current[:old_stderr] = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = Thread.current[:old_stderr] if Thread.current[:old_stderr]
    Thread.current[:old_stderr] = nil
  end
end
