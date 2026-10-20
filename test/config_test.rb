require_relative "test_helper"

class ConfigTest < TempRepoTest
  def test_loads_empty_config_when_no_files_exist
    config = Wt::Config.load(Dir.pwd)

    assert_empty config.copy
    assert_empty config.after_create
  end

  def test_loads_copy_and_after_create_from_wt_yml
    File.write(".wt.yml", <<~YAML)
      copy:
        - .env
        - config/master.key
      after_create:
        - bundle install
    YAML

    config = Wt::Config.load(Dir.pwd)

    assert_equal [".env", "config/master.key"], config.copy
    assert_equal ["bundle install"], config.after_create
  end

  def test_local_overrides_repo_config
    File.write(".wt.yml", <<~YAML)
      copy:
        - .env
      after_create:
        - bundle install
    YAML
    File.write(".wt.local.yml", <<~YAML)
      copy:
        - .env.local
    YAML

    config = Wt::Config.load(Dir.pwd)

    assert_equal [".env.local"], config.copy
    assert_equal ["bundle install"], config.after_create
  end
end
