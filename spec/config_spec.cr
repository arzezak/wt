require "./spec_helper"

describe Wt::Config do
  describe ".parse (via load)" do
    around_each do |example|
      dir = TestHelper.create_temp_repo
      Dir.cd(dir) do
        example.run
      end
      TestHelper.cleanup(dir)
    end

    it "loads empty config when no files exist" do
      config = Wt::Config.load(Dir.current)
      config.empty?.should be_true
    end

    it "loads copy and after_create from .wt.yml" do
      File.write(".wt.yml", <<-YAML)
      copy:
        - .env
        - config/master.key
      after_create:
        - bundle install
      YAML

      config = Wt::Config.load(Dir.current)
      config.copy.should eq([".env", "config/master.key"])
      config.after_create.should eq(["bundle install"])
    end

    it "local overrides repo config" do
      File.write(".wt.yml", <<-YAML)
      copy:
        - .env
      after_create:
        - bundle install
      YAML
      File.write(".wt.local.yml", <<-YAML)
      copy:
        - .env.local
      YAML

      config = Wt::Config.load(Dir.current)
      config.copy.should eq([".env.local"])
      config.after_create.should eq(["bundle install"])
    end
  end

  describe "#empty?" do
    it "is true when both lists are empty" do
      Wt::Config.new.empty?.should be_true
    end

    it "is false with copy entries" do
      Wt::Config.new(copy: [".env"]).empty?.should be_false
    end
  end
end
