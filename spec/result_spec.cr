require "./spec_helper"

describe Wt::Result do
  describe ".cd" do
    it "renders cd directive" do
      result = Wt::Result.cd("/some/path")
      io = IO::Memory.new
      result.render(io)
      io.to_s.should eq("cd /some/path\n")
    end

    it "escapes shell metacharacters in path" do
      result = Wt::Result.cd("/repo/.worktrees/foo;rm -rf ~")
      io = IO::Memory.new
      result.render(io)
      io.to_s.should eq("cd '/repo/.worktrees/foo;rm -rf ~'\n")
    end
  end

  describe ".print" do
    it "renders plain text" do
      result = Wt::Result.print("hello world")
      io = IO::Memory.new
      result.render(io)
      io.to_s.should eq("hello world\n")
    end
  end

  describe ".none" do
    it "renders nothing" do
      result = Wt::Result.none
      io = IO::Memory.new
      result.render(io)
      io.to_s.should eq("")
    end
  end
end
