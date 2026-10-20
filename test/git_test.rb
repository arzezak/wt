require_relative "test_helper"

class GitTest < TempRepoTest
  def test_worktree_list_returns_the_main_worktree
    entries = Wt::Git.new.worktree_list

    assert_equal 1, entries.size
    assert_equal Dir.pwd, entries.first.path
    refute_nil entries.first.branch
    assert entries.first.main?
  end

  def test_branch_exists_for_existing_branch
    assert Wt::Git.new.branch_exists?("main")
  end

  def test_branch_exists_for_missing_branch
    refute Wt::Git.new.branch_exists?("nonexistent")
  end

  def test_common_dir_returns_git_directory
    assert_equal File.join(Dir.pwd, ".git"), Wt::Git.new.common_dir
  end
end

class WorktreeEntryTest < Minitest::Test
  def test_short_head
    entry = Wt::Git::WorktreeEntry.new(path: "/tmp/repo", head: "abc1234567890", branch: "main", main: false)

    assert_equal "abc1234", entry.short_head
  end

  def test_name_from_path
    entry = Wt::Git::WorktreeEntry.new(path: "/tmp/repo/.worktrees/feature-foo", head: "abc1234", branch: "feature/foo", main: false)

    assert_equal "feature-foo", entry.name
  end
end
