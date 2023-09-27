require "claide"

module Pod
  class Command
    class Bridge < Command
      class Add < Bridge
        include Pod
        self.summary = "Add single local pod source from podfile.local"

        self.description = <<-DESC
            
        DESC
        self.arguments = [
          CLAide::Argument.new("NAME", true),
          CLAide::Argument.new("PATH", false),
          CLAide::Argument.new("ISFLUTTER", false),
        ]

        def self.options
          [
            ["--install", "install local dependencies"],
          ]
        end

        attr_accessor :install_check

        def initialize(argv)
          @name = argv.shift_argument
          @path = argv.shift_argument
          @isflutter = argv.shift_argument
          @install_check = argv.flag?("install")
          super
        end

        def run
          verify_podlcoal_exists!
          file = File.new(@podlocal_path.to_path, "r")
          new_context = ""
          has_name = false
          file.each_line do |line|
            context = line.strip.tr("“”‘’‛\"", "'")
            has_name = true if context.include?("'#{@name}'")
            if !line.include?("pod") || context[0, 1].eql?("#") == false || context.include?("'#{@name}'") == false
              new_context << line
              next
            end
            if context.include?("'#{@name}'")
              new_context << context.reverse!.chop!.reverse! + "\n"
            end
          end
          file.close

          if has_name == false
            new_context = ""
            path = @path
            puts Pathname.new(path)
            raise "工程路径不存在" unless Pathname.new(path).exist?
            status = @isflutter
            pod_str = "pod '#{@name}', :path => '#{path}'"
            pod_str << ", :isFlutter => true" if status.is_a?(String) && status.upcase.eql?("YES")
            file = File.new(@podlocal_path.to_path, "r")
            insert = false
            file.each_line do |line|
              if new_context.length > 0 && insert == false
                insert = true
                new_context << line + pod_str + "\n"
                next
              end
              new_context << line
            end
            file.close
          end

          write_pod_local_file(new_context)
          if @install_check
            Pod::Command::Bridge::Install.new(CLAide::ARGV.new([])).run()
          else
            puts "podlocal Add local source name: #{@name}, please execute 'pod bridge install'"
          end
        end

        def write_pod_local_file(new_context)
          file = File.new(@podlocal_path.to_path, "w+")
          file.puts(new_context)
          file.close
        end
      end
    end
  end
end
