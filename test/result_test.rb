require_relative "test_helper"
require "stringio"

class ResultTest < Minitest::Test
  def rendered(result)
    io = StringIO.new
    result.render(io)
    io.string
  end

  def test_cd_renders_cd_directive
    assert_equal "cd /some/path\n", rendered(Wt::Result.cd("/some/path"))
  end

  def test_cd_escapes_shell_metacharacters_in_path
    assert_equal "cd '/repo/.worktrees/foo;rm -rf ~'\n", rendered(Wt::Result.cd("/repo/.worktrees/foo;rm -rf ~"))
  end

  def test_cd_escapes_single_quotes_in_path
    assert_equal %(cd '/repo/it'"'"'s here'\n), rendered(Wt::Result.cd("/repo/it's here"))
  end

  def test_print_renders_plain_text
    assert_equal "hello world\n", rendered(Wt::Result.print("hello world"))
  end

  def test_none_renders_nothing
    assert_equal "", rendered(Wt::Result.none)
  end
end
