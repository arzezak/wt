require_relative "test_helper"

class LsCommandTest < TempRepoTest
  def test_lists_the_main_worktree
    exit_code, stdout, _ = TestHelper.run_wt("ls")

    assert_equal 0, exit_code
    assert_includes stdout, "main"
  end

  def test_prints_a_column_header
    exit_code, stdout, _ = TestHelper.run_wt("ls")

    assert_equal 0, exit_code
    header = stdout.lines.first
    assert_includes header, "BRANCH"
    refute_includes header, "HEAD"
    assert_includes header, "PATH"
  end

  def test_shortens_home_directory_to_tilde
    _, stdout, _ = TestHelper.run_wt("ls")

    path_column = stdout.lines.drop(1).map { |line| line.split(/\s{2,}/).last }
    path_column.each do |path|
      refute path.start_with?(Dir.home), "expected #{path} not to start with #{Dir.home}"
    end
  end

  def test_adds_the_head_column_with_long_flag
    exit_code, stdout, _ = TestHelper.run_wt("ls", "-l")

    assert_equal 0, exit_code
    header = stdout.lines.first
    assert_includes header, "BRANCH"
    assert_includes header, "HEAD"
    assert_includes header, "PATH"
  end

  def test_aligns_the_head_column_across_rows_with_long_flag
    TestHelper.run_wt("new", "a-much-longer-branch-name")

    _, stdout, _ = TestHelper.run_wt("ls", "-l")

    head_columns = stdout.lines.map { |line| line.index(/\b(HEAD|[0-9a-f]{7})\b/) }
    assert_equal 1, head_columns.uniq.size
  end

  def test_rejects_unknown_flags
    exit_code, _, stderr = TestHelper.run_wt("ls", "-b")

    refute_equal 0, exit_code
    assert_includes stderr, "unknown flag '-b'"
  end
end

class NewCommandTest < TempRepoTest
  def test_creates_a_worktree_and_emits_cd_directive
    exit_code, stdout, _ = TestHelper.run_wt("new", "test-feature")

    assert_equal 0, exit_code
    assert stdout.start_with?("cd "), "expected a cd directive, got: #{stdout}"
    assert_includes stdout, ".worktrees/test-feature"
    assert Dir.exist?(File.join(Dir.pwd, ".worktrees", "test-feature"))
  end

  def test_sanitizes_slashes_in_branch_names
    exit_code, stdout, _ = TestHelper.run_wt("new", "feature/slash")

    assert_equal 0, exit_code
    assert_includes stdout, ".worktrees/feature-slash"
  end

  def test_emits_cd_when_worktree_already_exists
    TestHelper.run_wt("new", "existing")

    exit_code, stdout, stderr = TestHelper.run_wt("new", "existing")

    assert_equal 0, exit_code
    assert stdout.start_with?("cd ")
    assert_includes stderr, "already exists"
  end

  def test_checks_out_existing_branch_into_new_worktree
    TestHelper.run_in("git", "branch", "side-branch")

    exit_code, stdout, _ = TestHelper.run_wt("new", "side-branch")

    assert_equal 0, exit_code
    assert_includes stdout, ".worktrees/side-branch"
  end

  def test_adds_worktrees_dir_to_git_exclude
    TestHelper.run_wt("new", "ignored-test")

    exclude_path = File.join(Dir.pwd, ".git", "info", "exclude")
    assert_includes File.read(exclude_path), ".worktrees/"
  end
end

class NewCommandHooksTest < TempRepoTest
  def test_runs_after_create_with_worktree_name_set
    File.write(".wt.yml", <<~YAML)
      after_create:
        - echo "name=$WT_WORKTREE_NAME" > marker.txt
    YAML

    TestHelper.run_wt("new", "feature/foo")

    marker = File.join(Dir.pwd, ".worktrees", "feature-foo", "marker.txt")
    assert_equal "name=feature-foo\n", File.read(marker)
  end

  def test_keeps_hook_output_off_stdout_so_the_cd_directive_stays_clean
    File.write(".wt.yml", <<~YAML)
      after_create:
        - echo "noise on stdout"
    YAML

    exit_code, stdout, stderr = TestHelper.run_wt("new", "quiet-branch")

    assert_equal 0, exit_code
    assert stdout.start_with?("cd ")
    refute_includes stdout, "noise"
    assert_includes stderr, "noise on stdout"
  end

  def test_stops_running_after_create_commands_on_first_failure
    File.write(".wt.yml", <<~YAML)
      after_create:
        - "false"
        - touch should-not-exist.txt
    YAML

    _, _, stderr = TestHelper.run_wt("new", "failing-branch")

    marker = File.join(Dir.pwd, ".worktrees", "failing-branch", "should-not-exist.txt")
    refute File.exist?(marker)
    assert_includes stderr, "after_create failed"
  end

  def test_copies_files_from_the_main_worktree
    File.write("shared.env", "SECRET=1")
    File.write(".wt.yml", <<~YAML)
      copy:
        - shared.env
    YAML

    TestHelper.run_wt("new", "copy-branch")

    copied = File.join(Dir.pwd, ".worktrees", "copy-branch", "shared.env")
    assert_equal "SECRET=1", File.read(copied)
  end

  def test_skips_a_missing_copy_source_with_a_warning_on_stderr
    File.write(".wt.yml", <<~YAML)
      copy:
        - does-not-exist.env
    YAML

    exit_code, _, stderr = TestHelper.run_wt("new", "missing-copy-branch")

    assert_equal 0, exit_code
    assert_includes stderr, "skipping does-not-exist.env"
  end

  def test_skips_hooks_entirely_with_no_hooks_flag
    File.write(".wt.yml", <<~YAML)
      after_create:
        - touch should-not-exist.txt
    YAML

    TestHelper.run_wt("new", "no-hooks-branch", "--no-hooks")

    marker = File.join(Dir.pwd, ".worktrees", "no-hooks-branch", "should-not-exist.txt")
    refute File.exist?(marker)
  end
end

class CdCommandTest < TempRepoTest
  def test_reports_single_worktree
    exit_code, stdout, stderr = TestHelper.run_wt("cd", "anything")

    assert_equal 0, exit_code
    assert_empty stdout
    assert_includes stderr, "only one worktree"
  end

  def test_resolves_by_exact_name
    TestHelper.run_wt("new", "target")

    exit_code, stdout, _ = TestHelper.run_wt("cd", "target")

    assert_equal 0, exit_code
    assert stdout.start_with?("cd ")
    assert_includes stdout, ".worktrees/target"
  end

  def test_resolves_by_unique_prefix
    TestHelper.run_wt("new", "unique-branch")

    exit_code, stdout, _ = TestHelper.run_wt("cd", "uni")

    assert_equal 0, exit_code
    assert_includes stdout, ".worktrees/unique-branch"
  end

  def test_fails_on_no_match
    TestHelper.run_wt("new", "some-branch")

    exit_code, _, stderr = TestHelper.run_wt("cd", "nonexistent")

    assert_equal 1, exit_code
    assert_includes stderr, "no worktree matching"
  end

  def test_returns_to_the_main_worktree_with_main
    TestHelper.run_wt("new", "leaf")

    exit_code, stdout, _ = TestHelper.run_wt("cd", "main")

    assert_equal 0, exit_code
    assert stdout.start_with?("cd ")
    refute_includes stdout, ".worktrees"
  end

  def test_returns_to_the_previous_worktree_with_dash
    previous = File.join(Dir.pwd, ".worktrees", "leaf")
    TestHelper.run_wt("new", "leaf")

    ENV["WT_PREV"] = previous
    begin
      exit_code, stdout, _ = TestHelper.run_wt("cd", "-")

      assert_equal 0, exit_code
      assert_includes stdout, "leaf"
    ensure
      ENV.delete("WT_PREV")
    end
  end

  def test_errors_on_dash_when_there_is_no_previous_worktree
    ENV.delete("WT_PREV")

    exit_code, stdout, stderr = TestHelper.run_wt("cd", "-")

    assert_equal 0, exit_code
    assert_empty stdout
    assert_includes stderr, "no previous worktree"
  end
end

class RmCommandTest < TempRepoTest
  def test_removes_a_worktree_by_name
    TestHelper.run_wt("new", "to-remove")
    wt_path = File.join(Dir.pwd, ".worktrees", "to-remove")
    assert Dir.exist?(wt_path)

    exit_code, _, stderr = TestHelper.run_wt("rm", "to-remove")

    assert_equal 0, exit_code
    assert_includes stderr, "removed to-remove"
    assert_includes stderr, "branch preserved"
    refute Dir.exist?(wt_path)
  end

  def test_reports_no_worktrees_to_remove
    exit_code, _, stderr = TestHelper.run_wt("rm", "anything")

    assert_equal 0, exit_code
    assert_includes stderr, "no worktrees to remove"
  end
end

class HelpCommandTest < TempRepoTest
  def test_shows_help_text
    exit_code, stdout, _ = TestHelper.run_wt("help")

    assert_equal 0, exit_code
    assert_includes stdout, "git worktrees"
  end

  def test_unknown_subcommand_fails_with_error
    exit_code, _, stderr = TestHelper.run_wt("bogus")

    assert_equal 1, exit_code
    assert_includes stderr, "unknown subcommand 'bogus'"
  end
end

class CompleteCommandTest < TempRepoTest
  def test_returns_worktree_names
    TestHelper.run_wt("new", "comp-test")

    exit_code, stdout, _ = TestHelper.run_wt("__complete", "worktrees")

    assert_equal 0, exit_code
    assert_includes stdout, "comp-test"
  end

  def test_returns_branch_names
    exit_code, stdout, _ = TestHelper.run_wt("__complete", "branches")

    assert_equal 0, exit_code
    assert_includes stdout, "main"
  end

  def test_returns_subcommands
    exit_code, stdout, _ = TestHelper.run_wt("__complete", "subcommands")

    assert_equal 0, exit_code
    assert_includes stdout, "cd"
    assert_includes stdout, "new"
    assert_includes stdout, "rm"
  end
end
