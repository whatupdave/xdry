
module XDry

  class Patcher

    def initialize
      @patched = {}
    end

    def insert_after pos, new_lines
      lines = patched_lines_of(pos.file_ref)
      line_index = pos.line_no - 1

      puts "INSERTING LINES:"
      new_lines.each { |line| puts "    #{line}" }
      puts "  AFTER LINE:"
      puts "    #{lines[line_index]}"

      lines[line_index+1 .. line_index] = new_lines.collect { |line| "#{line}\n" }
    end

    def save!
      for file_ref, lines in @patched
        original_path = file_ref.path
        ext = File.extname(original_path)
        new_path = File.join(File.dirname(original_path), File.basename(original_path, ext) + '.xdry' + ext)
        text = lines.join("")
        open(new_path, 'w') { |f| f.write text }
      end
    end

  private

    def patched_lines_of file_ref
      @patched[file_ref] ||= load_lines_of(file_ref)
    end

    def load_lines_of file_ref
      open(file_ref.path) { |f| f.lines.collect }
    end

  end

end