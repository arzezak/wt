require_relative "test_helper"

class RepoTest < TempRepoTest
  def setup
    super
    @repo = Wt::Repo.new(Wt::Git.new)
  end

  def test_main_repo_path_returns_the_repo_root
    assert_equal Dir.pwd, @repo.main_repo_path
  end

  def test_worktree_root_is_under_the_repo_root
    assert_equal File.join(Dir.pwd, ".worktrees"), @repo.worktree_root
  end

  def test_worktree_path_for_returns_path_under_worktrees
    assert_equal File.join(Dir.pwd, ".worktrees", "my-branch"), @repo.worktree_path_for("my-branch")
  end

  def test_worktree_path_for_sanitizes_slashes_to_dashes
    assert_equal File.join(Dir.pwd, ".worktrees", "feature-foo"), @repo.worktree_path_for("feature/foo")
  end

  def test_ensure_ignored_adds_worktrees_to_git_exclude
    @repo.ensure_ignored

    assert_includes File.read(exclude_path), ".worktrees/"
  end

  def test_ensure_ignored_is_idempotent
    @repo.ensure_ignored
    @repo.ensure_ignored

    count = File.read(exclude_path).each_line.count { |line| line.strip == ".worktrees/" }
    assert_equal 1, count
  end

  private

  def exclude_path
    File.join(Dir.pwd, ".git", "info", "exclude")
  end
end
