require "yc-cocoapods-bridge/command/bridge/add"
require "yc-cocoapods-bridge/command/bridge/list"
require "yc-cocoapods-bridge/command/bridge/remove"
require "yc-cocoapods-bridge/command/bridge/install"
require "yc-cocoapods-bridge/command/bridge/clear"

require "yc-cocoapods-bridge/command/parse/podfile"
require "yc-cocoapods-bridge/command/parse/podlocal"

require "yc-cocoapods-bridge/command/UI"

module Pod
  class Command
    class Bridge < Command
      include Config::Mixin
      self.summary = "local pod source supports bridge to mainProject"

      self.description = <<-DESC
        local pod source bridge to mainproject,
        support podfile.local(DSL), terminal add/remove pod[name]
        support flutter oc/swift binary library
      DESC

      self.abstract_command = true
      def self.options
        []
      end
      attr_accessor :work_path, :podfile_path, :podlocal_path

      # 内存存储数据
      attr_accessor :podlocal
      attr_accessor :flutter

      def initialize(argv)
        super
        @work_path = config.installation_root
      end

      def read_podfile!(path = nil)
        path = @podfile_path unless path
        @podfile = BridgeHelper::Podfile.from_path(path)
      end

      def read_flutter!
        return unless @podlocal.has_flutter
        @flutter = BridgeHelper::Flutter.new(@podlocal.flutter_path, @work_path)
      end

      def read_podlocal!
        @podlocal = BridgeHelper::Podlocal.from_path(@podlocal_path)
      end

      def hook_all_install
        Pod::HooksManager.register("yc-cocoapods-bridge", :post_install) do |context, _|
          @podfile.post_install_hook_block.call context if @podfile.post_install_hook_block
          context.pods_project.targets.each do |t|
            t.build_configurations.each do |config|
              puts config.build_settings
            end
          end
          if @podlocal.has_flutter
            require File.expand_path(File.join("packages", "flutter_tools", "bin", "podhelper"), @flutter.flutter_fvm_path)
            context.pods_project.targets.each do |t|
              flutter_additional_ios_build_settings(t)
            end
          end
        end
      end

      def read_podfile_lock
        file = File.new(config.lockfile_path, "r")
        has_local_source = false
        file.each_line do |line|
          has_local_source = true if line.include?(":path:")
          break if has_local_source
        end
        has_local_source
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
    end
  end
end
