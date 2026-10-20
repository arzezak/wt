require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require_relative "../wt"

module TestHelper
  # The binary under test: the Spinel build by default, or whatever WT_BIN
  # names (e.g. WT_BIN=bin/wt.rb to run the Ruby source under CRuby).
  BINARY_PATH = File.expand_path(ENV["WT_BIN"] || "build/bin/wt", File.expand_path("..", __dir__))

  def self.create_temp_repo
    dir = File.realpath(Dir.mktmpdir("wt-test"))
    run_in("git", "init", "-q", "-b", "main", dir: dir)
    File.write(File.join(dir, "README.md"), "test repo")
    run_in("git", "add", ".", dir: dir)
    run_in("git", "-c", "user.email=test@test.com", "-c", "user.name=Test", "commit", "-q", "-m", "initial", dir: dir)
    dir
  end

  def self.run_in(command, *args, dir: Dir.pwd)
    status, stdout, stderr = capture(command, args, dir)
    raise "#{command} #{args.join(" ")} failed in #{dir}: #{stderr}" unless status.success?

    stdout
  end

  def self.run_wt(*args, dir: Dir.pwd)
    status, stdout, stderr = capture(BINARY_PATH, args, dir)
    [status.exitstatus, stdout, stderr]
  end

  def self.capture(command, args, dir)
    stdout, stderr, status = Open3.capture3(command, *args, chdir: dir)
    [status, utf8(stdout).strip, utf8(stderr).strip]
  end

  # wt writes UTF-8 whatever the locale says (the help text and hook lines carry non-ASCII).
  def self.utf8(text)
    text.dup.force_encoding(Encoding::UTF_8)
  end
end

# Runs each test inside a fresh temp git repo, cleaning up afterwards.
class TempRepoTest < Minitest::Test
  def setup
    @previous_dir = Dir.pwd
    @repo_dir = TestHelper.create_temp_repo
    Dir.chdir(@repo_dir)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@repo_dir)
  end
end
