require "YC_Flutter_Bridge/command/parse/podfile"
require "YC_Flutter_Bridge/command/parse/podlocal"
require "YC_Flutter_Bridge/command/flutter/flutter.rb"
require "cocoapods"
require "claide"
require "cocoapods/open-uri"

module Pod
  class Command
    class Bridge < Command
      class Install < Bridge
        include Pod
        include BridgeHelper
        self.summary = "Install all local pod source from podfile.local"

        self.description = <<-DESC
            Bridge all dependencies defined in 'podfile.local' and cp prokect to cache
        DESC

        attr_accessor :bridge_temp_dir
        attr_accessor :bridge_temp_path

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
          @bridge_temp_path << "." + @podfile_extname if @podfile_extname
        end

        def reset_podfile
          `rm -rf #{@podfile_path}`
          `cp -f #{@bridge_temp_path} #{@work_path.to_path}`
          `rm -rf #{bridge_temp_dir}`
        end

        def create_six_ear
          p = File.open(@podfile_path, "w")
          context = @podfile.to_s
          p.write(context)
          p.close
        end

        def insert_flutter
          BridgeHelper::Flutter.remove_flutter_xcconfig(@podlocal, @work_path)
          return unless @podlocal.has_flutter
          @flutter.insert_extension(@podfile)
          @flutter.insert_flutter_xcconfig(@podlocal)
        end

        def insert_podlocal
          @podlocal.pod_merge(@podfile)
        end

        def insert_githook
          `rm -rf .git/bridge_git_hook`
          has_depend = read_podfile_lock
          return unless has_depend
          `touch .git/bridge_git_hook`

          p = File.open(".git/bridge_git_hook", "w")
          p.write("pod_has_dependency")
          p.close

          path = Pathname.new(".git/hooks/pre-commit")
          return unless path.exist? == false
          download_hook
          `unzip -q hooks.zip`
          `rm -rf __MACOSX`
          `cp -rf hooks .git`
          `rm -rf hooks`
          `rm -rf hooks.zip`
        end

        def download_hook
          open("https://b.yzcdn.cn/pod/hooks.zip") do |fin|
            size = fin.size
            download_size = 0
            open(File.basename("./hooks.zip"), "wb") do |fout|
              while buf = fin.read(1024)
                fout.write buf
                download_size += 1024
                STDOUT.flush
              end
            end
          end
        end

        def run
          @bridge_temp_dir = Pathname.new(@work_path + ".bridge_temp")
          verify_podlcoal_exists!
          verify_podfile_exists!
          create_temp_dir
          add_gitignore
          cache_podfile
          # block 存储 文件对应位置， @bridge_temp_path用到block记得传
          read_podfile!
          read_podlocal!
          read_flutter!

          insert_podlocal
          insert_flutter
          #core
          create_six_ear
          hook_all_install
          # use system `pod install` or include Pod use Pod::Command::Install.new(CLAide::ARGV.new([]))
          # dont use `pod install` this is subcommand, dont describe all pod info
          # system "pod install"
          installer = Pod::Command::Install.new(CLAide::ARGV.new([]))
          installer.run()
          # all raise lead to this command suspend, will execute “ensure”. It`s will copy origin podfile to origin path
        ensure
          reset_podfile
          insert_githook
        end
      end
    end
  end
end
