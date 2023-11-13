module BridgeHelper
  class TargetDefinition
    attr_accessor :sons
    attr_accessor :name

    attr_accessor :inherit_str
    attr_accessor :has_modular_headers
    attr_accessor :has_frameworks
    attr_accessor :inhibit_all_warnings
    attr_accessor :pod_hash
    attr_accessor :pod_install
    

    def initialize(name)
      @sons = []
      @pod_hash = Hash.new
      @pod_install = Hash.new
      @name = name
      @has_modular_headers = false
      @has_frameworks = false
      @inhibit_all_warnings = false
    end

    def birth_son(son)
      @sons << son
    end

    def store_pod(name, *param)
      pod_str = "  pod \"#{name}\""
      pod_str += parse_pod(param) if param.is_a?(Array)
      pod_hash[name] = pod_str
    end

    def store_use_modular_headers!
      @has_modular_headers = true
    end

    def store_use_frameworks!
      @has_frameworks = true
    end

    def store_inherit!(path)
      @inherit_str = path.to_s
    end

    def store_install!(name, value)
      pod_install[name] = value
    end 

    def store_inhibit_all_warnings!
      @inhibit_all_warnings = true
    end

    def to_s

      context = ""
      
      pod_install.each do |key, value|
        value.each do |sub_key, sub_value|
          context << "install! '#{key}', :#{sub_key} => #{sub_value}" + "\n"
        end
      end 

      context << "\ntarget \"#{@name}\" do\n"
      context << "  use_frameworks!\n" if @has_frameworks
      context << "  use_modular_headers!\n" if @has_modular_headers
      context << "  inherit! :" + @inherit_str + "\n" if @inherit_str

      pod_hash.reverse_each do |key, value|
        context << value + "\n"
      end
      sons.each do |son_target|
        context << son_target.to_s
      end
      context << "end\n\n"
    end

    private

    # core
    # pod "FBRetainCycleDetector", :git => "git@github.com:facebook/FBRetainCycleDetector.git", :branch => "master", :configurations => ["Debug"]
    def parse_pod(arr)
      pod_str = ""
      arr.each do |item|
        if item.is_a?(String)
          pod_str << ", \"" + item + "\""
        elsif item.is_a?(Hash)
          item.each do |key, value|
            pod_str << ", :" + key.to_s + " => "
            pod_str << value.to_s if value.is_a?(Array)
            pod_str << "\"#{value.to_s}\"" if value.is_a?(String)
            pod_str << true.to_s if value.is_a?(TrueClass)
            pod_str << false.to_s if value.is_a?(FalseClass)
            pod_str << ""
          end
        else
          raise StandardError, "The #{item.class} dont support, In #{__LINE__}"
        end
      end
      pod_str
    end
  end
end
