require 'optparse'
require 'logger'
require 'fileutils'
require '../lib/CollectUtils'
require '../lib/MaskUtils'
require '../lib/ValidUtils'
include Diagtool

module Diagtool
	class DiagUtils
		def initialize(params)
			time = Time.new
                        @time_format = time.strftime("%Y%m%d%0k%M%0S")
			@conf = parse_diagconf(params)
			@conf[:time] = @time_format
                        @conf[:workdir] = @conf[:output_dir] + '/' + @time_format
			FileUtils.mkdir_p(@conf[:workdir])
			diaglog = @conf[:workdir] + '/diagtool.output'
			@masklog = './mask_' + @time_format + '.json'
			@logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  				"#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
			})
			@logger_file = Logger.new(diaglog, formatter: proc {|severity, datetime, progname, msg|
                                "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
                        })
			diaglogger_info("Parsing command options...")
                        diaglogger_info("   Option : Output directory = #{@conf[:output_dir]}")
                        diaglogger_info("   Option : Mask = #{@conf[:mask]}")
                        diaglogger_info("   Option : Exclude list = #{@conf[:exlist]}")
                        diaglogger_info("   Option : Hash Seed = #{@conf[:seed]}")
		end
		def diagtool()
			loglevel = 'WARN'
			diaglogger_info("Initializing parameters...")
			c = CollectUtils.new(@conf, loglevel)
			c_env = c.export_env()
			diaglogger_info("[Collect] Loading the environment parameters...")
                        diaglogger_info("[Collect]    operating system = #{c_env[:os]}")
                        diaglogger_info("[Collect]    kernel version = #{c_env[:kernel]}")
                        diaglogger_info("[Collect]    td-agent conf path = #{c_env[:tdconf_path]}")
                        diaglogger_info("[Collect]    td-agent conf file = #{c_env[:tdconf]}")
                        diaglogger_info("[Collect]    td-agent log path = #{c_env[:tdlog_path]}")
                        diaglogger_info("[Collect]    td-agent log = #{c_env[:tdlog]}")
			m = MaskUtils.new(@conf, loglevel)
			v = ValidUtils.new(loglevel)
							
			diaglogger_info("[Collect] Collecting log files of td-agent...")
			tdlog = c.collect_tdlog()
			diaglogger_info("[Collect] log files of td-agent are stored in #{tdlog}")

			diaglogger_info("[Collect] Collecting config file of td-agent...")
			tdconf = c.collect_tdconf()
			diaglogger_info("[Collect] config file is stored in #{tdconf}")

			diaglogger_info("[Collect] Collecting config file of OS log...")
                        oslog = c.collect_oslog()
			if @conf[:mask] == 'yes'
				diaglogger_info("[Mask] Masking OS log file : #{oslog}...")
				oslog = m.mask_tdlog(oslog, clean = true)
			end
                        diaglogger_info("[Collect] config file is stored in #{oslog}")

			diaglogger_info("[Collect] Collecting date/time information...")
			ntp = c.collect_ntp(command="chrony")
			diaglogger_info("[Collect] date/time information is stored in #{ntp}")
			
			diaglogger_info("[Collect] Collecting netstat information...")
                        netstat = c.collect_netstat()
			if @conf[:mask] == 'yes'
				diaglogger_info("[Mask] Masking netstat file : #{netstat}...")
				netstat = m.mask_tdlog(netstat, clean = true)
			end
                        diaglogger_info("[Collect] netstat information is stored in #{netstat}")		

			diaglogger_info("[Collect] Collecting systctl information...")
			sysctl = c.collect_sysctl()
			diaglogger_info("[Collect] sysctl information is stored in #{sysctl}")
			
			diaglogger_info("[Valid] Validating systctl information...")
			ret, sysctl = v.valid_sysctl(sysctl)
			list =  sysctl.keys
			list.each do |k|
				if sysctl[k]['result'] == 'correct'
					diaglogger_info("[Valid]    Sysctl: #{k} => #{sysctl[k]['value']} is correct (recommendation is #{sysctl[k]['recommend']})")
				elsif sysctl[k]['result'] == 'incorrect'
					diaglogger_warn("[Valid]    Sysctl: #{k} => #{sysctl[k]['value']} is incorrect (recommendation is #{sysctl[k]['recommend']})")
				end
			end

			diaglogger_info("[Collect] Collecting ulimit information...")
			ulimit = c.collect_ulimit()
			diaglogger_info("[Collect] ulimit information is stored in #{ulimit}")

			diaglogger_info("[Valid] Validating ulimit information...")
			ret, rec, val = v.valid_ulimit(ulimit)
			if ret == true
				diaglogger_info("[Valid]    ulimit => #{val} is correct (recommendation is >#{rec})")
			else
				diaglogger_warn("[Valid]    ulimit => #{val} is incorrect (recommendation is >#{rec})")
			end

			if @conf[:mask] == 'yes'
        			diaglogger_info("[Mask] Masking td-agent config file : #{tdconf}...")
        			m.mask_tdlog(tdconf, clean = true)
        			tdlog.each do | file |
                			diaglogger_info("[Mask] Masking td-agent log file : #{file}...")
                			filename = file.split("/")[-1]
                			if filename.include?(".gz")
                        			m.mask_tdlog_gz(file, clean = true)
                			elsif
                        			m.mask_tdlog(file, clean = true)
                			end
        			end
			end
			diaglogger_info("[Mask] Export mask log file : #{@masklog}")
			m.export_masklog(@masklog)
			tar_file = c.compress_output()
			diaglogger_info("[Collect] Generate tar file #{tar_file}")
		end

		def parse_diagconf(params)
			options = {
        			:output_dir => '../output',
        			:mask => 'yes',
        			:exlist => [],
        			:exfile => '',
        			:seed => ''
       	 		}
        		if params[:output] != nil
                		if Dir.exist?(params[:output])
                        		options[:output_dir] = params[:output]
                		else
                        		raise "output directory '#{output_dir}' does not exist"
                		end
        		end
        		if params[:mask] == nil
                		options[:mask] = 'yes'
        		else
                		if params[:mask] == 'yes' || params[:mask] == 'no'
                        		options[:mask] = params[:mask]
                		else
                        		raise "invalid arguments '#{params[:mask]}' : input of '-m|--mask' should be 'yes' or 'no'"
                		end
        		end
        		options[:exlist] = params[:"exclude-list"] if params[:"exclude-list"] != nil
        		if params[:"exclude-file"] != nil
                		f = params[:"exclude-file"]
                		if File.exist?(f)
                        		File.readlines(f).each do  |l|
                                		options[:exlist].append(l.gsub(/\n/,''))
                        		end
                		else
                        		raise "#{params[:"exclude-file"]} : No such file or directory"
                		end
        		end
			options[:exlist] = options[:exlist].uniq 
        		options[:seed] = params[:"hash-seed"] if params[:"hash-seed"] != nil
			return options	
		end
		def diaglogger_debug(str)
                        @logger.debug(str)
                        @logger_file.debug(str)
                end
		def diaglogger_info(str)
			@logger.info(str)
			@logger_file.info(str)
		end
		def diaglogger_warn(str)
                        @logger.warn(str)
                        @logger_file.warn(str)
                end
		def diaglogger_error(str)
                        @logger.error(str)
                        @logger_file.error(str)
                end
	end
end
