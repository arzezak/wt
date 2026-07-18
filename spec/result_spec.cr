require "./spec_helper"

private def rendered(result : Wt::Result) : String
  io = IO::Memory.new
  result.render(io)
  io.to_s
end

describe Wt::Result do
  describe ".cd" do
    it "renders cd directive" do
      rendered(Wt::Result.cd("/some/path")).should eq("cd /some/path\n")
    end

    it "escapes shell metacharacters in path" do
      rendered(Wt::Result.cd("/repo/.worktrees/foo;rm -rf ~")).should eq("cd '/repo/.worktrees/foo;rm -rf ~'\n")
    end
  end

  describe ".print" do
    it "renders plain text" do
      rendered(Wt::Result.print("hello world")).should eq("hello world\n")
    end
  end

  describe ".none" do
    it "renders nothing" do
      rendered(Wt::Result.none).should eq("")
    end
  end
end
