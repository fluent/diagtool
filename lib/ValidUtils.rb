require 'logger'

module Diagtool
	class ValidUtils
		def initialize(log_level)
			@logger = Logger.new(STDOUT, level: log_level, formatter: proc {|severity, datetime, progname, msg|
  				"#{datetime}: [Validutils] [#{severity}] #{msg}\n"
		    	})
			@def_ulimit = "65535".to_i
			@def_sysctl = Hash.new()
			@def_sysctl = { :net_core_somaxconn => "1024",
					:net_core_netdev_max_backlog => "5000",
					:net_core_rmem_max => "16777216",
					:net_core_wmem_max => "16777216",
					:net_ipv4_tcp_wmem => ["4096", "12582912", "16777216"],
					:net_ipv4_tcp_rmem => ["4096", "12582912", "16777216"],
					:net_ipv4_tcp_max_syn_backlog => "8096",
					:net_ipv4_tcp_slow_start_after_idle => "0",
					:net_ipv4_tcp_tw_reuse => "1",
					:net_ipv4_ip_local_port_range => ["10240", "65535"]}
			@logger.debug("Initialize Validation Utils:")
			@logger.debug("    Default ulimit: #{@def_ulimit}")
			@logger.debug("    Default sysctl: #{@def_sysctl}")
		end
		def valid_ulimit(ulimit_file)
			@logger.info("Loading ulimit file: #{ulimit_file}")
			File.readlines(ulimit_file).each { |line|
				if line.chomp.to_i >= @def_ulimit.to_i
					@logger.info("    ulimit => #{line.chomp.to_i} is correct")
					return true, @def_ulimit.to_i, line.chomp.to_i
				else
					@logger.warn("    ulimit => #{line.chomp.to_i} is incorrect, should be #{@def_ulimit}")
					return false, @def_ulimit.to_i, line.chomp.to_i
				end 
			}
		end
		def valid_sysctl(sysctl_file)
			h = Hash.new()
			v = Hash.new { |i,j| i[j] = Hash.new(&h.default_proc) }
			@logger.info("Loading sysctl file: #{sysctl_file}")
			File.readlines(sysctl_file).each{ |line|
				if line.include?("net")
					line_net = line.chomp.gsub(".","_").split("=")
					key = line_net[0].strip.to_sym
					if line_net[1].strip! =~ /\s/
						value = line_net[1].split(/\s/)
					else
						value= line_net[1]
					end
					h[key] = value
					if @def_sysctl[key] == value
						@logger.info("#{key} => #{value} is correct")
						v[key]['value'] = value
						v[key]['recommend'] = @def_sysctl[key]	
						v[key]['result'] = "correct"
					else
						@logger.warn("#{key} => #{value} is incorrect, should be #{@def_sysctl[key]}")
						v[key]['value'] = value
                                                v[key]['recommend'] = @def_sysctl[key]
						v[key]['result'] = "incorrect"
					end
				end
			}
			if h == @sysctl
				return true, v
			else
				return false, v
			end
		end
	end
end

