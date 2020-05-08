require 'optparse'
require 'logger'
require '../lib/CollectUtils'
require '../lib/MaskUtils'
require '../lib/ValidUtils'
include Diagtool

module Diagtool
	class DiagUtils
		def initialize(params)
			@logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  				"#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
			})
			time = Time.new
                        @time_format = time.strftime("%Y%m%d%0k%M%0S")
			@conf = parse_diagconf(params)
			@logger.info("Parsing command options...")
                        @logger.info("   Option : Output directory = #{@conf[:output_dir]}")
                        @logger.info("   Option : Mask = #{@conf[:mask]}")
                        @logger.info("   Option : Exclude list = #{@conf[:exlist]}")
                        @logger.info("   Option : Exclude list = #{@conf[:seed]}")
			@conf[:time] = @time_format
		end
		def diagtool()
			loglevel = 'WARN'
			@logger.info("Initializing parameters...")
			c = CollectUtils.new(@conf, loglevel)
			c_env = c.export_env()
			@logger.info("[Collect] Loading the environment parameters...")
                        @logger.info("[Collect]    operating system = #{c_env[:os]}")
                        @logger.info("[Collect]    kernel version = #{c_env[:kernel]}")
                        @logger.info("[Collect]    td-agent conf path = #{c_env[:tdconf_path]}")
                        @logger.info("[Collect]    td-agent conf file = #{c_env[:tdconf]}")
                        @logger.info("[Collect]    td-agent log path = #{c_env[:tdlog_path]}")
                        @logger.info("[Collect]    td-agent log = #{c_env[:tdlog]}")
			m = MaskUtils.new(@conf, loglevel)
			v = ValidUtils.new(loglevel)
							
			@logger.info("Collecting log files of td-agent...")
			tdlog = c.collect_tdlog()
			@logger.info("log files of td-agent are stored in #{tdlog}")

			@logger.info("Collecting config file of td-agent...")
			tdconf = c.collect_tdconf()
			@logger.info("config file is stored in #{tdconf}")

			@logger.info("Collecting date/time information...")
			ntp = c.collect_ntp(command="chrony")
			@logger.info("date/time information is stored in #{ntp}")

			@logger.info("Collecting systctl information...")
			sysctl = c.collect_sysctl()
			@logger.info("sysctl information is stored in #{sysctl}")
			
			@logger.info("Validating systctl information...")
			ret, sysctl = v.valid_sysctl(sysctl)
			list =  sysctl.keys
			list.each do |k|
				if sysctl[k]['result'] == 'correct'
					@logger.info("[Valid]    Sysctl: #{k} => #{sysctl[k]['value']} is correct (recommendation is #{sysctl[k]['recommend']})")
				elsif sysctl[k]['result'] == 'incorrect'
					@logger.warn("[Valid]    Sysctl: #{k} => #{sysctl[k]['value']} is incorrect (recommendation is #{sysctl[k]['recommend']})")
				end
			end

			@logger.info("Collecting ulimit information...")
			ulimit = c.collect_ulimit()
			@logger.info("ulimit information is stored in #{ulimit}")

			@logger.info("Validating ulimit information...")
			ret, rec, val = v.valid_ulimit(ulimit)
			if ret == true
				@logger.info("[Valid]    ulimit => #{val} is correct (recommendation is >#{rec})")
			else
				@logger.warn("[Valid]    ulimit => #{val} is incorrect (recommendation is >#{rec})")
			end

			if @conf[:mask] == 'yes'
        			@logger.info("Masking td-agent config file : #{tdconf}...")
        			m.mask_tdlog(tdconf, clean = true)
        			tdlog.each do | file |
                			@logger.info("Masking td-agent log file : #{file}...")
                			filename = file.split("/")[-1]
                			if filename.include?(".gz")
                        			m.mask_tdlog_gz(file, clean = true)
                			elsif
                        			m.mask_tdlog(file, clean = true)
                			end
        			end
			end
			m.export_masklog('mask.log')
			tar_file = c.compress_output()
			@logger.info("Generate tar file #{tar_file}")
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
			puts options
			return options	
		end
	end
end
