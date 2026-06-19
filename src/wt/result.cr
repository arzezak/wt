module Wt
  struct Result
    getter cd_path : String?
    getter stdout : String?

    def initialize(*, @cd_path : String? = nil, @stdout : String? = nil)
    end

    def self.cd(path : String) : Result
      new(cd_path: path)
    end

    def self.print(text : String) : Result
      new(stdout: text)
    end

    def self.none : Result
      new
    end

    def render(io : IO) : Nil
      if path = @cd_path
        io.puts "cd #{path}"
      elsif text = @stdout
        io.puts text
      end
    end
  end
end
