require "yc-cocoapods-bridge/command/parse/target_definition"

module BridgeHelper
  class Podfile
    module DSL
      def source(name, priority = 0)
        puts "让我康康 is #{name} #{priority}"
        @all_source = [] unless @all_source
        @all_source << name
        
      end
      # def source(name)
      #   @all_source = [] unless @all_source
      #   @all_source << name
      # end

      def platform(name, dev_version = nil)
        @all_platform = "platform :" + name.to_s
        @all_platform << +", \"#{dev_version}\"" if dev_version
      end

      def target(name)
        puts "让我康康 is #{name}"
        parent = @current_target_definition
        news_target = TargetDefinition.new(name)
        parent.birth_son(news_target) if parent
        @current_target_definition = news_target
        yield if block_given?
        @current_target_definition = parent if parent
        
      end

      def use_modular_headers!
        @current_target_definition.store_use_modular_headers!
      end

      def use_frameworks!
        @current_target_definition.store_use_frameworks!
      end

      def inhibit_all_warnings!  
        @current_target_definition.store_inhibit_all_warnings!
      
      end

      def inherit!(path)
        @current_target_definition.store_inherit!(path)
      end

      def install!(name, value)
        puts "狗东西 #{name} #{value}"
        puts "install! #{name} #{value}"
      end


      def post_install(&block)
        raise "Specifying multiple `post_install` hooks is unsupported." unless !@post_install_hook_block
        
        @post_install_hook_block = block if block_given?
      end

      def plugin(name)
        @all_plugin = [] unless @all_plugin
        @all_plugin << name
      end

      def pod(name = nil, *requirements)
        raise StandardError, "A dependency require name" unless name
        @current_target_definition.store_pod(name, *requirements)
      end
    end
  end
end
