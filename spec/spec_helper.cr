require "spec"
require "file_utils"
require "../src/wt/log"
require "../src/wt/result"
require "../src/wt/git"
require "../src/wt/repo"
require "../src/wt/resolver"
require "../src/wt/config"
require "../src/wt/completion"
require "../src/wt/commands/*"

module TestHelper
  BINARY_PATH = File.expand_path(File.join(__DIR__, "..", "bin", "wt"))

  def self.create_temp_repo : String
    dir = File.tempname("wt-test")
    Dir.mkdir_p(dir)
    run_in(dir, "git", "init")
    run_in(dir, "git", "config", "user.email", "test@test.com")
    run_in(dir, "git", "config", "user.name", "Test")
    File.write(File.join(dir, "README.md"), "test repo")
    run_in(dir, "git", "add", ".")
    run_in(dir, "git", "commit", "-m", "initial")
    dir
  end

  def self.cleanup(dir : String) : Nil
    FileUtils.rm_rf(dir)
  end

  def self.run_in(dir : String, command : String, *args : String) : String
    process = Process.new(
      command,
      args.to_a,
      output: Process::Redirect::Pipe,
      error: Process::Redirect::Pipe,
      chdir: dir
    )
    output = process.output.gets_to_end
    error = process.error.gets_to_end
    status = process.wait
    unless status.success?
      raise "#{command} #{args.join(" ")} failed in #{dir}: #{error}"
    end
    output.strip
  end

  def self.run_wt(dir : String, *args : String) : {Int32, String, String}
    binary = BINARY_PATH
    process = Process.new(
      binary,
      args.to_a,
      output: Process::Redirect::Pipe,
      error: Process::Redirect::Pipe,
      chdir: dir
    )
    stdout = process.output.gets_to_end
    stderr = process.error.gets_to_end
    status = process.wait
    {status.exit_code, stdout.strip, stderr.strip}
  end
end
