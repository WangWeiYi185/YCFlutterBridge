require "cocoapods-local-bridge/command/parse/dsl"

# 暂时不需要这里解析了，逐行读取podfile了
module BridgeHelper
  class Podfile
    include BridgeHelper::Podfile::DSL
    include Pod

    attr_accessor :extension
    attr_accessor :all_source
    attr_accessor :all_plugin
    attr_accessor :current_target_definition
    attr_accessor :absolut_path
    attr_accessor :all_platform
    attr_accessor :post_install_hook_block # version 1.0
    attr_accessor :post_install_hook_context
    attr_accessor :post_install_hook_val # 存储podfile里的轮训val，

    def initialize(path, &block)
      @absolut_path = path
      @extension = ""
      instance_eval(&block) unless !block
      read_podfile(path)
    end

    def read_podfile(path)
      file = File.new(path, "r+")
      start_line = false
      @post_install_hook_context = ""
      file.each_line do |line|
        if line.include?("post_install")
          temp = line.split("|")
          raise "podfile dont vailable in #{line}" unless temp.length == 3
          @post_install_hook_val = temp[1].strip
          start_line = true
        end
        if start_line == true
          @post_install_hook_context << line
        end
      end
      file.close
    end

    def self.from_path(path)
      path_name = Pathname.new(path)
      raise "pathname parse fail" unless path_name.exist?
      raise "不支持" unless ["", "rb", ".podfile", "podlocal"].include?(path_name.extname)
      contents ||= File.open(path, "r:utf-8", &:read)
      contents.encode!("UTF-8") if contents.respond_to?(":encoding") && contents.encoding.name != "UTF-8"
      contents.tr!("“”‘’‛", %(""'''))

      p = Podfile.new(path) do
        begin
          eval(contents, nil, path_name.to_s)
        rescue => exception
          message = "Invalid #{path_name.basename}, exception: #{exception.message}"
          raise Pod::DSLError.new(message, path, exception, contents)
        end
      end
    end

    def to_s
      context = ""
      context << allsouce_to_s
      context << "\n\n"
      context << allPlugin_to_s
      context << "\n\n"
      # context << "project '#{@current_target_definition.name}', { \n'Debug' => :debug,\n'Profile' => :release,\n'Release' => :release,\n}\n"
      context << @all_platform + "\n"
      context << @current_target_definition.to_s if @current_target_definition
      context << "\n\n" + @post_install_hook_context
      context << "\n\n" + @extension
    end

    def allsouce_to_s
      return "" unless @all_source.is_a?(Array)
      source_context = ""
      @all_source.each do |source|
        source_context << "source " "\"#{source}\"\n"
      end
      source_context
    end

    def allPlugin_to_s
      return "" unless @all_plugin.is_a?(Array)
      plugin_context = ""
      @all_plugin.each do |plugin|
        plugin_context << "plugin " "\"#{plugin}\"\n"
      end
      plugin_context
    end
  end
end
