module Wt
  class Result
    attr_reader :cd_path, :stdout

    def initialize(cd_path: nil, stdout: nil)
      @cd_path = cd_path
      @stdout = stdout
    end

    def self.cd(path)
      new(cd_path: path)
    end

    def self.print(text)
      new(stdout: text)
    end

    def self.none
      new
    end

    def render(io)
      if @cd_path
        io.puts "cd #{Result.shell_quote(@cd_path)}"
      elsif @stdout
        io.puts @stdout
      end
    end

    # Quotes one word for the shell wrapper's eval: a word of safe characters
    # goes through bare, anything else is single-quoted.
    def self.shell_quote(arg)
      return "''" if arg.empty?
      return arg unless arg.match?(/[^a-zA-Z0-9%+,\-.\/:=@_]/)

      "'" + arg.gsub("'", %('"'"')) + "'"
    end
  end
end
