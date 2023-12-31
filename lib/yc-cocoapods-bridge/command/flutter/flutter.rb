require "yc-cocoapods-bridge/command/parse/podfile"

module BridgeHelper
  class Flutter
    attr_accessor :flutter_path

    attr_accessor :flutter_sdk_path

    attr_accessor :application_path

    attr_accessor :podlocal

    include Xcodeproj

    def initialize(flutter_path, application_path, podlocal)
      @flutter_path = flutter_path
      @application_path = application_path
      @podlocal = podlocal
      input = `which flutter`
      if input.is_a?(String) # 软连接
        @flutter_sdk_path = input.split("/bin")[0]
      end
      raise "flutter not find" unless @flutter_sdk_path
    end

    def insert_flutter_xcconfig(podlocal)
      create_flutter_Dir
      project_path = ""
      Dir.foreach(@application_path) do |file|
        file_obj = Pathname.new(file)
        raise "current Dir show multiple xcodeproj file" if file_obj.extname.include?("xcodeproj") && project_path.length > 0
        project_path = file_obj.to_path if file_obj.extname.include?("xcodeproj")
      end
      project = Xcodeproj::Project.open(project_path)
      target = nil
      project.targets.each do |tg|
        target = tg if tg.name.eql?(podlocal.name)
      end

      insert_run_script_to_target("Flutter Run", "/bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" build", target, project)
      add_run_script_to_target("Flutter Thin Binary", "/bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" embed_and_thin", target, project)

      group_main = project.main_group.find_subpath("Flutter", true)
      path = Pathname.new(@application_path + "Flutter")
      add_file_reference_to_group(target, project, path.to_path, group_main)

      group_main = project.main_group.find_subpath("Config", true)
      path = Pathname.new(@application_path + "Config")
      add_file_reference_to_group(target, project, path.to_path, group_main)

      text_embed_text = '#include? "Flutter/Generated.xcconfig"'
      Pathname.new(@application_path).each_child(true) do |child1|
        if child1.directory?
          child1.each_child(true) do |child2|
            if child2.directory?
              child2.each_child(true) do |child3|
                # 检查是否是.xcconfig文件
                if child3.file? && child3.extname == '.xcconfig' && child3.basename.to_s.include?('Debug')
                  # 读取文件内容
                  contents = File.read(child3)
      
                  # 检查文本是否已存在
                  unless contents.include?(text_embed_text)
                    # 添加文本到内容的开始
                    contents = text_embed_text + "\n" + contents
      
                    # 写回文件
                    File.open(child3, 'w') { |file| file.write(contents) }
                  end
                end
              end
            end
          end
        end
      end
   

    end

    def insert_extension(podfile)
      raise "podfile is #{podfile.class} no support" unless podfile.is_a?(BridgeHelper::Podfile)
      flutter_post_install = "require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), \"#{@flutter_sdk_path}\")\n"
      temp_arr = podfile.post_install_hook_context.split("\n")
      flutter_insert = false
      temp_arr.each do |context|
        if flutter_insert == true
          flutter_insert = false
          flutter_post_install << "#{podfile.post_install_hook_val}.pods_project.targets.each do |t| \n flutter_additional_ios_build_settings(t) \n end\n"
        end
        flutter_post_install << context + "\n"
        flutter_insert = true if context.include?("post_install")
      end
      podfile.post_install_hook_context = flutter_post_install
      #podfile.pod("FlutterPluginRegistrant", { :path => File.join("#{flutter_path}/.ios/Flutter", "FlutterPluginRegistrant"), :inhibit_warnings => true })
      podfile.extension << "ENV['COCOAPODS_DISABLE_STATS'] = 'true'\nENV['selfbuild'] = 'true'\n"
      podfile.extension << "pod_flutter_application_path = \"#{@flutter_path}\"\n"
      podfile.extension << "def replace_flutter_plugins_dependencies(application_path)\n"
      podfile.extension << "f = \"../.flutter-plugins-dependencies\"\n"
      podfile.extension << "File.delete(f) if File::exists?(f)\n"
      podfile.extension << "\nend\n\n" # `cp -a \#{application_path}/.flutter-plugins-dependencies ..`
      podfile.extension << "replace_flutter_plugins_dependencies(pod_flutter_application_path)\n"
      podfile.extension << "flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))\n"
    end

    def self.remove_flutter_xcconfig(podlocal, application_path)
      project_path = ""
      Dir.foreach(application_path) do |file|
        file_obj = Pathname.new(file)
        raise "current Dir show multiple xcodeproj file" if file_obj.extname.include?("xcodeproj") && project_path.length > 0
        project_path = file_obj.to_path if file_obj.extname.include?("xcodeproj")
      end
      project = Xcodeproj::Project.open(project_path)
      target = nil
      project.targets.each do |tg|
        target = tg if tg.name.eql?(podlocal.name)
      end

      group_main = project.main_group.find_subpath("Flutter", true)
      path = Pathname.new(application_path + "Flutter")
      remove_file_reference_to_group(target, project, path.to_path, group_main)

      group_main = project.main_group.find_subpath("Config", true)
      path = Pathname.new(application_path + "Config")
      remove_file_reference_to_group(target, project, path.to_path, group_main)

      remove_run_script_to_target("Flutter Run", target, project)
      remove_run_script_to_target("Flutter Thin Binary", target, project)

      project.save

      system `rm -rf Flutter`
      system `rm -rf Config`
    end

    private

    def create_flutter_Dir
      system "mkdir Flutter"
      system "mkdir Config"
      project_path = ""
      Dir.foreach(@application_path) do |file|
        file_obj = Pathname.new(file)
        raise "current Dir show multiple xcodeproj file" if file_obj.extname.include?("xcodeproj") && project_path.length > 0
        project_path = file_obj.to_path if file_obj.extname.include?("xcodeproj")
      end
      
      project = Xcodeproj::Project.open(project_path)
      target = nil
      project.targets.each do |tg|
        target = tg if tg.name.eql?(@podlocal.name)
      end
      generated_context = "FLUTTER_ROOT=#{flutter_sdk_path}\nFLUTTER_APPLICATION_PATH=#{flutter_path}\nFLUTTER_TARGET=${FLUTTER_APPLICATION_PATH}/lib/main.dart\nPACKAGE_CONFIG=${FLUTTER_APPLICATION_PATH}/.dart_tool/package_config.json\nFLUTTER_BUILD_DIR=build\nSYMROOT=${SOURCE_ROOT}/../build/ios\nFLUTTER_BUILD_NAME=1.0.0\nFLUTTER_BUILD_NUMBER=1\nDART_OBFUSCATION=false\nTRACK_WIDGET_CREATION=true\nTREE_SHAKE_ICONS=false"
      flutter_context = "#include \"../Flutter/Generated.xcconfig\""
      debug_context = "#include \"Flutter.xcconfig\"\n#include? \"Pods/Target Support Files/Pods-#{target}/Pods-#{target}.debug.xcconfig\""
      release_context = "#include \"Flutter.xcconfig\"\n#include? \"Pods/Target Support Files/Pods-#{target}/Pods-#{target}.release.xcconfig\""

      add_file_to_workPath("Debug.xcconfig", debug_context)
      add_file_to_workPath("Release.xcconfig", release_context)
      add_file_to_workPath("Flutter.xcconfig", flutter_context)
      add_file_to_workPath("Generated.xcconfig", generated_context)

      system `mv Debug.xcconfig Config`
      system `mv Flutter.xcconfig Config`
      system `mv Release.xcconfig Config`
      system `mv Generated.xcconfig Flutter`
    end

    def add_file_to_workPath(file_name, context)
      f = File.new(file_name, "w+")
      f.puts(context)
      f.close
    end

    def self.remove_run_script_to_target(script_name, target, project)
      phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && p.name.eql?(script_name) }
      target.build_phases.delete(phase) if phase
      project.save()
    end

    def add_run_script_to_target(script_name, context, target, project)
      phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && p.name.eql?(script_name) }
      return if phase
      phase = target.new_shell_script_build_phase(script_name)
      phase.shell_script = context
      project.save()
    end

    def insert_run_script_to_target(script_name, context, target, project)
      puts "真想给你一个大逼斗"
      
      phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && p.name.eql?(script_name) }
      puts "#{phase}"
      return if phase
      phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
      phase.name = script_name
      phase.shell_script = context
      index = 0
      target.build_phases.each do |p|
        break unless p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && p.name.include?("Check Pods Manifest.lock")
        index += 1
      end

      target.build_phases.insert(index, phase)
      project.save()
    end

    def add_file_reference_to_group(target, project, directory_path, to_group)
      if to_group and File::exist?(directory_path)
        Dir.foreach(directory_path) do |entry|
          if entry != "." and entry != ".." and entry != ".DS_Store"
            file_reference = to_group.new_file(directory_path + "/#{entry}")
            target.add_file_references([file_reference])
          end
        end
        project.save
      end
    end

    def self.remove_file_reference_to_group(target, project, directory_path, to_group)
      if to_group and File::exist?(directory_path)
        Dir.foreach(directory_path) do |entry|
          if entry != "." and entry != ".." and entry != ".DS_Store"
            file_reference = to_group.find_file_by_path(to_group.name + "/#{entry}")
            target.source_build_phase.remove_build_file(file_reference.referrers.last) if file_reference && file_reference.referrers && file_reference.referrers.last
            target.source_build_phase.remove_file_reference([file_reference])
          end
        end
        project.save
      end
      to_group.clear
    end
  end
end
