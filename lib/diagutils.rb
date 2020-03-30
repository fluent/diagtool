require 'fileutils'
require 'open3'
require 'logger'
require '../lib/maskutils'

module Diagtool
    class Diagutils
	    include Maskutils
	    def initialize(output_dir, exlist, loglevel)
		    @logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  			"#{datetime}: [Diagutils] [#{severity}] #{msg}\n"
		    })
		    @time = Time.new
		    @time_format = @time.strftime("%Y%m%d%0k%M")
		    @output_dir = output_dir
		    @workdir = @output_dir+'/'+@time_format
		    FileUtils.mkdir_p(@workdir)
		    @tdenv = get_tdenv()
		    @tdconf = @tdenv['FLUENT_CONF'].split('/')[-1]
		    @tdconf_path = @tdenv['FLUENT_CONF'].gsub(@tdconf,'')
		    @tdlog =  @tdenv['TD_AGENT_LOG_FILE'].split('/')[-1]
		    @tdlog_path = @tdenv['TD_AGENT_LOG_FILE'].gsub(@tdlog,'')
		    @oslog_path = '/var/log/'       # As of Centos8.1
		    @oslog = 'messages'             # As of Centos8.1
		    @sysctl_path = '/etc/'          # As of Centos8.1
		    @sysctl = 'sysctl.conf'         # As of Centos8.1	
		    @exclude_list = exlist
		    load_exlist(@exclude_list)

		    @logger.info("Loading the environment parameters...")
		    @logger.info("    td-agent conf path = #{@tdconf_path}")
		    @logger.info("    td-agent conf file = #{@tdconf}")
		    @logger.info("    td-agent log path = #{@tdlog_path}")
		    @logger.info("    td-agent log = #{@tdlog}")
	    end
	    def get_tdenv()
		    stdout, stderr, status = Open3.capture3('systemctl cat td-agent')
		    env_dict = {}
		    File.open(@workdir+'/td-agent_env.txt', 'w') do |f|
			    f.puts(stdout)
		    end
		    stdout.split().each do | l |
			    if l.include?('Environment')
				    env_dict[l.split('=')[1]] = l.split('=')[2]
			    end
		    end
		    return env_dict
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
		    FileUtils.mkdir_p(@workdir+@sysctl_path)
		    FileUtils.cp(@sysctl_path+@sysctl, @workdir+@sysctl_path)
		    return @workdir+@sysctl_path+@sysctl
	    end
	    def collect_ulimit()
		    stdout, stderr, status = Open3.capture3("ulimit -n")
		    File.open(@workdir+'/ulimit_info.output', 'w') do |f|
			    f.puts(stdout)
		    end
		    return @workdir+'/ulimit_info.output'
	    end
	    def collect_ntp()
		    stdout_date, stderr_date, status_date = Open3.capture3("date")
		    stdout_ntp, stderr_ntp, status_ntp = Open3.capture3("chronyc sources")
		    File.open(@workdir+'/ntp_info.output', 'w') do |f|
			    f.puts(stdout_date)
			    f.puts(stdout_ntp)
		    end
		    return @workdir+'/ntp_info.output'
	    end
	    def mask_tdconf(input_file)
		    f = File.open(input_file+'.mask', 'w')
		    File.readlines(input_file).each do |line|
			    line_masked = mask_tdconf_inspector(line)
			    f.puts(line_masked)
		    end
		    f.close
		    FileUtils.rm(input_file)
	    end
	    def mask_tdlog(input_file)
		    f = File.open(input_file+'.mask', 'w')
		    File.readlines(input_file).each do |line|
			    line_masked = mask_tdlog_inspector(line)
			    f.puts(line_masked)
		    end
		    f.close
		    FileUtils.rm(input_file)
	    end
	    def mask_tdlog_gz(input_file)
		    f = File.open(input_file+'.mask', 'w')
		    gunzip_file = input_file+'.mask'+'.tmp'
		    Open3.capture3("gunzip --keep -c #{input_file} > #{gunzip_file}")
		    File.readlines(gunzip_file).each do |line|
			    line_masked = mask_tdlog_inspector(line)
			    f.puts(line_masked)
		    end
		    f.close
		    FileUtils.rm(gunzip_file)
		    FileUtils.rm(input_file)
	    end
	    def compress_output()
		    tar_file = @output_dir+'/diagout-'+@time_format+'.tar.gz'
		    stdout, stderr, status = Open3.capture3("tar cvfz #{tar_file} #{@workdir}")
 		    return tar_file
	    end
    end
end
