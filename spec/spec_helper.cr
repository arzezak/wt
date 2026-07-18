require "spec"
require "file_utils"
require "../src/wt/**"

module TestHelper
  BINARY_PATH = File.expand_path(File.join(__DIR__, "..", "bin", "wt"))

  # Runs the example inside a fresh temp git repo, cleaning up afterwards.
  # Use as: around_each { |example| TestHelper.with_temp_repo(example) }
  def self.with_temp_repo(example) : Nil
    dir = create_temp_repo
    begin
      Dir.cd(dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  def self.create_temp_repo : String
    dir = File.tempname("wt-test")
    Dir.mkdir_p(dir)
    run_in("git", "init", dir: dir)
    File.write(File.join(dir, "README.md"), "test repo")
    run_in("git", "add", ".", dir: dir)
    run_in("git", "-c", "user.email=test@test.com", "-c", "user.name=Test", "commit", "-m", "initial", dir: dir)
    dir
  end

  def self.run_in(command : String, *args : String, dir : String = Dir.current) : String
    status, stdout, stderr = capture(command, args.to_a, dir)
    unless status.success?
      raise "#{command} #{args.join(" ")} failed in #{dir}: #{stderr}"
    end
    stdout
  end

  def self.run_wt(*args : String, dir : String = Dir.current) : {Int32, String, String}
    status, stdout, stderr = capture(BINARY_PATH, args.to_a, dir)
    {status.exit_code, stdout, stderr}
  end

  private def self.capture(command : String, args : Array(String), dir : String) : {Process::Status, String, String}
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    status = Process.run(command, args, output: stdout, error: stderr, chdir: dir)
    {status, stdout.to_s.strip, stderr.to_s.strip}
  end
end
