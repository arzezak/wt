module Wt
  module Picker
    def self.fzf_available? : Bool
      !!Process.find_executable("fzf")
    end

    def self.pick(entries : Array(Git::WorktreeEntry), query : String? = nil) : Git::WorktreeEntry?
      return nil if entries.empty?

      lines = entries.map { |entry| "#{entry.name}\t#{entry.branch || entry.short_head}\t#{entry.path}" }
      input = lines.join("\n")

      fzf_args = [
        "--style", "minimal",
        "--select-1",
        "--exit-0",
        "--delimiter", "\t",
        "--with-nth", "1,2",
      ]
      fzf_args += ["--query", query] if query

      process = Process.new(
        "fzf",
        fzf_args,
        input: Process::Redirect::Pipe,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Inherit,
      )
      process.input.print(input)
      process.input.close

      selection = process.output.gets_to_end.strip
      status = process.wait
      return nil unless status.success? && !selection.empty?

      selected_name = selection.split('\t').first
      entries.find { |entry| entry.name == selected_name }
    end
  end
end
