require "YC_Flutter_Bridge/command/parse/podfile"

module BridgeHelper
  class Podlocal
    attr_accessor :pod_hash
    attr_accessor :name
    attr_accessor :has_flutter
    attr_accessor :flutter_path
    attr_accessor :absolut_path

    def initialize(path, &block)
      @absolut_path = path
      @pod_hash = Hash.new
      @has_flutter = false
      instance_eval(&block) unless !block
    end

    def self.from_path(path)
      path_name = Pathname.new(path)
      raise "pathname parse fail" unless path_name.exist?
      raise "不支持" unless ["", "rb", ".podfile", ".local"].include?(path_name.extname)
      contents ||= File.open(path, "r:utf-8", &:read)
      contents.encode!("UTF-8") if contents.respond_to?(":encoding") && contents.encoding.name != "UTF-8"
      contents.tr!("“”‘’‛", %(""'''))

      p = Podlocal.new(path) do
        begin
          eval(contents, nil, path_name.to_s)
        rescue => exception
          message = "Invalid #{path_name.basename}, exception: #{exception.message}"
          raise Pod::DSLError.new(message, path, exception, contents)
        end
      end
    end

    def hook_target(name)
      @name = name
      yield if block_given?
    end

    def pod(name = nil, *requirements)
      raise StandardError, "A dependency require name" unless name
      raise StandardError, "pod #{name} paramters dont is hash" unless requirements.is_a?(Array)
      pod_str = "  pod \"#{name}\""
      requirements.each do |item|
        if item.is_a?(Hash)
          item.each do |key, value|
            @has_flutter = true if key == :isFlutter && value.is_a?(TrueClass)
            next if key == :isFlutter
            pod_str << ", :" + key.to_s + " => "
            pod_str << value.to_s if value.is_a?(Array)
            pod_str << "\"#{value.to_s}\"" if value.is_a?(String)
          end
          @flutter_path = item[:path] if item.include?(:isFlutter)
        else
          raise StandardError, "The #{item.class} dont support, In #{__LINE__}"
        end
      end
      pod_hash[name] = pod_str
    end

    def pod_merge(podfile)
      raise "podfile is #{podfile.class} no support" unless podfile.is_a?(BridgeHelper::Podfile)
      target = fetch_target(podfile.current_target_definition)
      @pod_hash.each do |key, value|
        target.pod_hash[key] = value if target.pod_hash.include?(key)
      end
      podfile
    end

    def fetch_target(current_target)
      return current_target if @name.eql?(current_target.name)
      return nil if current_target.sons == nil || current_target.sons.is_a?(Array) == false || current_target.sons.length == 0
      targets = []
      current_target.sons.each do |son|
        target = fetch_target(son)
        targets << target unless target == nil
      end
      raise "podlocal dont support multiple sample target name" unless targets.length == 1
      targets.first
    end
  end
end
