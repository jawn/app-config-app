require 'sinatra'
require 'sinatra/contrib'
require 'rack/flash'

module AppCfg
  module Helpers
    def client_name(username = nil)
      "#{username || session[:username]}Client"
    end

    def diffs_for(resource)
      diffs = parse_diffs try p4diff resource
      if diffs.length and diffs[0]
        diffs[0][:diffs]
      else
        ''
      end
    end

    def ensure_escaped(resource)
      if /[\t\f\r\n\a&\|<>:;\*\?!%\$\^`~@#\[\]\(\)\{\}\+=\\]/.match resource or
          resource.include? '..' or (resource.include? '"' and resource.include? "'")
        raise 'Resource contains invalid characters'
      elsif resource.include? "'"
        "\"#{resource}\""
      elsif resource.include? '"'
        "'#{resource}'"
      elsif resource.include? ' '
        "'#{resource}'"
      else
        resource
      end
    end

    def ensure_words(word, name)
      if /[^\w+\-\.]/.match word
        raise "Illegal characters in '#{name}'"
      end
    end

    def extension_of(resource)
      resource.split('.').pop
    end

    def p4(username = nil, password = nil)
      p4port = ARGV[0]
      if p4port.nil?
        p4port = 'localhost:1666'
      end
      username ||= session[:username]
      password ||= session[:password]
      ensure_words username, 'username'
      ensure_words password, 'password'
      "p4 -p #{p4port} -u #{username} -P #{password} -c #{client_name username}"
    end

    def p4add(resource)
      [%x[#{p4} add #{ensure_escaped resource} 2>&1], $?]
    end

    def p4commit(message)
      message = message.gsub /\s+/, ' '
      message = message.gsub /"/, '\''
      [%x[#{p4} submit -d "#{message}" 2>&1], $?]
    end

    def p4diff(file = nil)
      [%x[#{p4} diff #{ensure_escaped file || ''} 2>&1], $?]
    end

    def p4edit(resource)
      [%x[#{p4} edit #{ensure_escaped resource} 2>&1], $?]
    end

    def p4revert(resource)
      [%x[#{p4} revert #{ensure_escaped resource} 2>&1], $?]
    end

    def p4sync(username = nil, password = nil)
      [%x[#{p4 username, password} sync 2>&1], $?]
    end

    def parse_diffs(diffs)
      files = []
      diffs.lines.each do |line|
        if /^==== .+#{Regexp.escape working_copy}\/(.+) ====$/.match line
          files.push({
                         filename: Regexp.last_match(1),
                         diffs: '',
                     })
        elsif files[-1]
          files[-1][:diffs] += line
        end
      end
      files
    end

    def path_to(resource)
      File.join working_copy, resource
    end

    def sync
      time = Time.now.to_i
      if session[:last_sync].nil? or session[:last_sync] < time - 30
        try p4sync
        session[:last_sync] = time
        request.logger.debug 'performed sync'
      end
    end

    def try(message, code = nil)
      if code.nil?
        message, code = message
      end
      if code != 0
        request.logger.error message
        flash[:error] = message
        redirect '/error'
      end
      message
    end

    def working_copy
      File.join File.dirname(__FILE__), 'wc', session[:username]
    end
  end
end
