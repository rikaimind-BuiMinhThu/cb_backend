require "colorize"

class Log
  @@debug_mode = :both
  # :stdout
  # :file
  # :both

  class << self
    def log_txt_file
      Rails.root + "/tmp/log.txt"
    end

    def debug_mode(debug_mode = :both)
      @@debug_mode = debug_mode
    end

    def info(message, tab_level = 0)
      case @@debug_mode
      when :stdout
        puts "[INFO]:\t\t#{tab(tab_level)}#{message}".green
      when :file
        write_log_to_file "#{Time.now} [INFO]:\t\t#{tab(tab_level)}#{message}"
      when :both
        puts "[INFO]:\t\t#{tab(tab_level)}#{message}".green
        write_log_to_file "#{Time.now} [INFO]:\t\t#{tab(tab_level)}#{message}"
      end
    end

    def error(message, tab_level = 0)
      case @@debug_mode
      when :stdout
        puts "[ERROR]:\t\t#{message}".red
      when :file
        write_log_to_file "#{Time.now} [ERROR]:\t\t#{tab(tab_level)}#{message}"
      when :both
        puts "[ERROR]:\t\t#{tab(tab_level)}#{message}".red
        write_log_to_file "#{Time.now} [ERROR]:\t\t#{tab(tab_level)}#{message}"
      end
    end

    def warning(message, tab_level = 0)
      case @@debug_mode
      when :stdout
        puts "[WARN]:\t\t#{tab(tab_level)}#{message}".yellow
      when :file
        write_log_to_file "#{Time.now} [WARN]:\t\t#{tab(tab_level)}#{message}"
      when :both
        puts "[WARN]:\t\t#{tab(tab_level)}#{message}".yellow
        write_log_to_file "#{Time.now} [WARN]:\t\t#{tab(tab_level)}#{message}"
      end
    end

    def delete_log_file
      return unless File.exist? log_txt_file

      File.delete log_txt_file
      info "Deleted #{log_txt_file}"
    end

    def write_log_to_file(message)
      File.open(log_txt_file, "a") { |f| f.puts message }
    end

    def tab(tab_level = 0)
      tab_str = ""

      tab_level.times { |_| tab_str += "\t" }
      tab_str
    end
  end
end
