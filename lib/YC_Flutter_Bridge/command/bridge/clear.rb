require "YC_Flutter_Bridge/command/bridge/install"
require "claide"

module Pod
  class Command
    class Bridge < Command
      class Clear < Bridge
        include Pod
        self.summary = "Clear all local pod source from podfile.local and install all remote source"

        self.description = <<-DESC
            
        DESC

        def run
          verify_podlcoal_exists!
          file = File.new(@podlocal_path.to_path, "r")
          new_context = ""
          file.each_line do |line|
            context = line.strip
            if !line.include?("pod") || context[0, 1].eql?("#")
              new_context << line
              next
            end
            new_context << "#" + line if !(context[0, 1].eql?("#"))
          end
          file.close
          file = File.new(@podlocal_path.to_path, "w+")
          file.puts(new_context)
          file.close
          Pod::Command::Bridge::Install.new(CLAide::ARGV.new([])).run()
        end
      end
    end
  end
end
