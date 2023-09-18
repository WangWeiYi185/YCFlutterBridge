require "claide"

module Pod
  class Command
    class Bridge < Command
      class Remove < Bridge
        include Pod
        self.summary = "Remove single local pod source from podfile.local"

        self.description = <<-DESC
            
        DESC
        self.arguments = [
          CLAide::Argument.new("NAME", true),
        ]

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def run
          verify_podlcoal_exists!
          file = File.new(@podlocal_path.to_path, "r")
          new_context = ""
          file.each_line do |line|
            context = line.strip.tr("“”‘’‛\"", "'")
            if !line.include?("pod") || context[0, 1].eql?("#") || context.include?("'#{@name}'") == false
              new_context << line
              next
            end
            new_context << "#" + line if context.include?("'#{@name}'")
          end
          file.close
          file = File.new(@podlocal_path.to_path, "w+")
          file.puts(new_context)
          file.close
          puts "podlocal remove local source name: #{@name}, please execute 'pod bridge install'"
        end
      end
    end
  end
end
