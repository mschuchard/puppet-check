# utility methods totally not edited from StackOverflow
class Utils
  # captures stdout from a block: out = capture_stdout { code }
  def self.capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  # captures stderr from a block: err = capture_stderr { code }
  def self.capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end
