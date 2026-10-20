require "yaml"

module Wt
  class Config
    attr_reader :copy, :after_create

    def initialize(copy: [], after_create: [])
      @copy = copy
      @after_create = after_create
    end

    def self.load(main_repo_path)
      global = load_file(global_path)
      repo = load_file(File.join(main_repo_path, ".wt.yml"))
      local = load_file(File.join(main_repo_path, ".wt.local.yml"))
      merge([global, repo, local])
    end

    def self.global_path
      config_home = ENV["XDG_CONFIG_HOME"] || File.join(Dir.home, ".config")
      File.join(config_home, "wt", "config.yml")
    end

    def self.load_file(path)
      return nil unless File.exist?(path)

      parse(File.read(path))
    rescue Psych::SyntaxError => e
      Log.puts "failed to parse #{path}: #{e.message}"
      nil
    end

    def self.parse(content)
      yaml = YAML.safe_load(content)
      yaml = {} unless yaml.is_a?(Hash)
      Config.new(copy: string_array(yaml, "copy"), after_create: string_array(yaml, "after_create"))
    end

    # The key's list of strings, or an empty list when it is absent or anything else.
    def self.string_array(yaml, key)
      node = yaml[key]
      return [] unless node.is_a?(Array) && node.all? { |item| item.is_a?(String) }

      node.map(&:to_s)
    end

    # Later configs win per key: a non-empty list replaces the earlier one.
    def self.merge(configs)
      copy = []
      after_create = []
      configs.each do |config|
        next unless config

        copy = config.copy unless config.copy.empty?
        after_create = config.after_create unless config.after_create.empty?
      end
      Config.new(copy: copy, after_create: after_create)
    end
  end
end
