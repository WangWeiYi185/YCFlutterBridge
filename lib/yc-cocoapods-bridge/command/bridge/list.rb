require "yc-cocoapods-bridge/command/parse/podfile"
require "yc-cocoapods-bridge/command/parse/podlocal"

module Pod
  class Command
    class Bridge < Command
      class List < Bridge
        include Config::Mixin
        # def self.options
        #   [
        #     ["--check", "find all local dependencies. If you have, use command puts return false. It is used in git commit hook"],
        #   ]
        # end

        self.summary = "show all dependencies of the podlocal, or use '--check' check podlock has local path"

        # attr_accessor :commit_hook_check

        def initialize(argv)
          super
          # @commit_hook_check = argv.flag?("check")
        end

        def run
          # if @commit_hook_check
          #   exit 1 if read_podfile_lock
          # else
          show_dependencies
          # end
        end

        def show_dependencies
          verify_podlcoal_exists!
          read_podlocal!
          puts "all local pod dependencies:" if podlocal.pod_hash.length > 0
          podlocal.pod_hash.each do |key, value|
            puts key + "\n"
          end
        end
      end
    end
  end
end
