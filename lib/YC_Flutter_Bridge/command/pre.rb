require "cocoapods-local-bridge/command/parse/podfile"
require "cocoapods-local-bridge/command/parse/podlocal"
require "cocoapods-local-bridge/command/flutter/flutter.rb"
require "claide"

module Pod
  class Command
    class Pre < Command
      include Config::Mixin
      include Pod
      attr_accessor :work_path, :podfile_path, :podlocal_path, :bridge_temp_dir, :bridge_temp_path

      def read_podfile!(path = nil)
        path = @podfile_path unless path
        @podfile = BridgeHelper::Podfile.from_path(path)
      end

      def read_podlocal!
        @podlocal = BridgeHelper::Podlocal.from_path(@podlocal_path)
      end

      def verify_podlcoal_exists!
        local_path = @work_path + "Podfile.local"
        raise Informative, "No `Podfile' found in the project directory." unless local_path
        path = Pathname.new(local_path)
        raise Informative, "No `Podfile.local' found in the project directory." unless path.exist?
        @podlocal_path = path
      end

      def verify_podfile_exists!
        raise Informative, "No `Podfile' found in the project directory." unless config.podfile_path
        path = Pathname.new(config.podfile_path)
        raise Informative, "No `Podfile' found in the project directory." unless path.exist?
        @podfile_path = path.to_s
      end

      def create_temp_dir
        path = Pathname.new(@work_path + ".bridge_temp")
        if path.exist?
          `rm -rf #{path}`
        end
        `mkdir #{path}`
      end

      def add_gitignore
        git_ignore = Pathname.new(@work_path + ".gitignore")
        has_add = false
        File.open(git_ignore, "r") do |file|
          file.each_line do |line|
            has_add = true unless line != ".bridge_temp/\n"
          end
        end
        f = open(git_ignore, "a")
        unless has_add == true
          begin
            f.puts "\n\n#pod_plugin\n.bridge_temp/\n.symlinks"
          rescue => exception
            puts exception
          end
        end
      end

      def cache_podfile
        `cp #{@podfile_path} #{@bridge_temp_dir}`
        podfile_extname = Pathname.new(@podfile_path).extname
        @bridge_temp_path = @bridge_temp_dir.to_s + "/podfile"
      end

      def reset_podfile
        `rm -rf #{@podfile_path}`
        `cp -f #{@bridge_temp_path} #{@work_path.to_path}`
        `rm -rf #{bridge_temp_dir}`
      end

      def create_six_ear
        p = File.open(@podfile_path, "w")
        context = ""
        context << "ENV['local'] = 'true'\n" if @podlocal.has_flutter
        context << @podfile.to_s
        p.write(context)
        p.close
      end

      def insert_podlocal
        @podlocal.pod_merge(@podfile)
      end

      def run
        
        @work_path = config.installation_root
        @bridge_temp_dir = Pathname.new(@work_path + ".bridge_temp")
        verify_podfile_exists!
        verify_podlcoal_exists!

        create_temp_dir
        add_gitignore
        cache_podfile

        read_podfile!
        read_podlocal!
        BridgeHelper::Flutter.remove_flutter_xcconfig(@podlocal, @work_path)
        insert_podlocal
        create_six_ear
        installer = Pod::Command::Install.new(CLAide::ARGV.new([]))
        installer.run()
      ensure
        reset_podfile
      end
    end
  end
end
