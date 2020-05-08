require 'fileutils'
require 'open3'
require 'logger'

module Diagtool
	class CollectUtils
		def initialize(conf, log_level)
		    	@logger = Logger.new(STDOUT, level: log_level, formatter: proc {|severity, datetime, progname, msg|
  				"#{datetime}: [Diagutils] [#{severity}] #{msg}\n"
		    	})
		    	#@time = Time.new
		    	#@time_format = @time.strftime("%Y%m%d%0k%M%0S")
		    	#@output_dir = output_dir
			@time_format = conf[:time]
			@output_dir = conf[:output_dir]

		    	@workdir = conf[:workdir]
		    	FileUtils.mkdir_p(@workdir)
		    	
			@tdenv = get_tdenv()
		    	@tdconf = @tdenv['FLUENT_CONF'].split('/')[-1]
		    	@tdconf_path = @tdenv['FLUENT_CONF'].gsub(@tdconf,'')
		    	@tdlog =  @tdenv['TD_AGENT_LOG_FILE'].split('/')[-1]
		    	@tdlog_path = @tdenv['TD_AGENT_LOG_FILE'].gsub(@tdlog,'')
			
			@osenv = get_osenv()
		    	@oslog_path = '/var/log/'
		    	@oslog = 'messages'
		    	@sysctl_path = '/etc/'
		    	@sysctl = 'sysctl.conf'        

		    	@logger.info("Loading the environment parameters...")
			@logger.info("    operating system = #{@osenv['Operating System']}")
			@logger.info("    kernel version = #{@osenv['Kernel']}")
		    	@logger.info("    td-agent conf path = #{@tdconf_path}")
		    	@logger.info("    td-agent conf file = #{@tdconf}")
		    	@logger.info("    td-agent log path = #{@tdlog_path}")
		    	@logger.info("    td-agent log = #{@tdlog}")
	    	end
		def get_osenv()
			stdout, stderr, status = Open3.capture3('hostnamectl')
			os_dict = {}
			stdout.each_line { |l|
        			s = l.split(":")
        			os_dict[s[0].chomp.strip] = s[1].chomp.strip
			}
			File.open(@workdir+'/os_env.output', 'w') do |f|
                                f.puts(stdout)
                        end
			return os_dict
		end
	    	def get_tdenv()
			stdout, stderr, status = Open3.capture3('systemctl cat td-agent')
		    	env_dict = {}
		    	File.open(@workdir+'/td-agent_env.output', 'w') do |f|
				f.puts(stdout)
		    	end
		    	stdout.split().each do | l |
				if l.include?('Environment')
					env_dict[l.split('=')[1]] = l.split('=')[2]
			    	end
		    	end
		    	return env_dict
	    	end
		def export_env()
			env = {
                                :os => @osenv['Operating System'],
                                :kernel => @osenv['Kernel'],
                                :tdconf => @tdconf,
                                :tdconf_path => @tdconf_path,
                                :tdlog => @tdlog,
                                :tdlog_path => @tdlog_path
                        }
			return env
		end
	    	def collect_tdconf()
		    	FileUtils.mkdir_p(@workdir+@tdconf_path)
		    	FileUtils.cp(@tdconf_path+@tdconf, @workdir+@tdconf_path)
		    	return @workdir+@tdconf_path+@tdconf
	    	end
	    	def collect_tdlog()
		    	FileUtils.mkdir_p(@workdir+@tdlog_path)
		    	FileUtils.cp_r(@tdlog_path, @workdir+@oslog_path)
		    	return Dir.glob(@workdir+@tdlog_path+@tdlog+'*')
	    	end
	    	def collect_sysctl()
		    	FileUtils.mkdir_p(@workdir+@sysctl_path)
		    	FileUtils.cp(@sysctl_path+@sysctl, @workdir+@sysctl_path)
		    	return @workdir+@sysctl_path+@sysctl
	    	end
	    	def collect_oslog()
		    	FileUtils.mkdir_p(@workdir+@oslog_path)
		    	FileUtils.cp(@oslog_path+@oslog, @workdir+@oslog_path)
		    	return @workdir+@oslog_path+@oslog
	    	end
	    	def collect_ulimit()
			output = @workdir+'/ulimit_n.output'
		    	stdout, stderr, status = Open3.capture3("ulimit -n")
		    	File.open(output, 'w') do |f|
			 	f.puts(stdout)
		    	end
		    	return output
	    	end
		def collect_netstat()
			output = @workdir+'/netstat_n.output'
                        stdout, stderr, status = Open3.capture3("netstat -n")
                        File.open(output, 'w') do |f|
                                f.puts(stdout)
                        end
                        return output
                end
	    	def collect_ntp(command)
		    	stdout_date, stderr_date, status_date = Open3.capture3("date")
		    	stdout_ntp, stderr_ntp, status_ntp = Open3.capture3("chronyc sources") if command == "chrony"
		    	stdout_ntp, stderr_ntp, status_ntp = Open3.capture3("ntpq -p") if command == "ntp"
		    	File.open(@workdir+'/ntp_info.output', 'w') do |f|
			    	f.puts(stdout_date)
			    	f.puts(stdout_ntp)
		    	end
		    	return @workdir+'/ntp_info.output'
	    	end
	    	def compress_output()
		    	tar_file = @output_dir+'/diagout-'+@time_format+'.tar.gz'
		    	stdout, stderr, status = Open3.capture3("tar cvfz #{tar_file} #{@workdir}")
 		    	return tar_file
	    	end
    	end
end
