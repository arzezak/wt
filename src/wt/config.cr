require "yaml"

module Wt
  class Config
    getter copy : Array(String)
    getter after_create : Array(String)

    def initialize(@copy = [] of String, @after_create = [] of String)
    end

    def empty? : Bool
      @copy.empty? && @after_create.empty?
    end

    def self.load : Config
      global = load_file(global_path)
      repo = load_file(repo_path)
      local = load_file(local_path)
      merge(global, repo, local)
    end

    private def self.global_path : String
      File.join(ENV.fetch("XDG_CONFIG_HOME", File.join(Path.home, ".config")), "wt", "config.yml")
    end

    private def self.repo_path : String?
      File.join(Repo.main_repo_path, ".wt.yml")
    end

    private def self.local_path : String?
      File.join(Repo.main_repo_path, ".wt.local.yml")
    end

    private def self.load_file(path : String?) : Config?
      return nil unless path && File.exists?(path)
      parse(File.read(path))
    rescue ex : YAML::ParseException
      STDERR.puts "wt: warning: failed to parse #{path}: #{ex.message}"
      nil
    end

    private def self.parse(content : String) : Config
      yaml = YAML.parse(content)
      copy = extract_string_array(yaml, "copy")
      after_create = extract_string_array(yaml, "after_create")
      Config.new(copy: copy, after_create: after_create)
    end

    private def self.extract_string_array(yaml : YAML::Any, key : String) : Array(String)
      node = yaml[key]?
      return [] of String unless node
      node.as_a.map(&.as_s)
    rescue
      [] of String
    end

    private def self.merge(*configs : Config?) : Config
      copy = [] of String
      after_create = [] of String
      configs.each do |config|
        next unless config
        copy = config.copy unless config.copy.empty?
        after_create = config.after_create unless config.after_create.empty?
      end
      Config.new(copy: copy, after_create: after_create)
    end
  end
end
