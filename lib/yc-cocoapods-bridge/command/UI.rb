module BridgeHelper
  module UI
    def error(msg)
      puts "\033[31m" + msg + "\033[0m\n"
    end

    def warning(msg)
      puts "\033[43m" + msg + "\033[0m\n"
    end
  end
end
