#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'logger'
require 'fileutils'
require 'fluent/diagtool/collectutils'
require 'fluent/diagtool/maskutils'
require 'fluent/diagtool/validutils'
include Diagtool

module Diagtool
  class DiagUtils
    def initialize(params)
      time = Time.new
      @time_format = time.strftime("%Y%m%d%0k%M%0S")
      @conf = parse_diagconf(params)
      @cmd_list = [
      	"ps -eo pid,ppid,stime,time,%mem,%cpu,cmd",
	"cat /proc/meminfo",
	"netstat -plan",
	"netstat -s",
      ]
    end
    
    def run_precheck()
      prechecklog = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
        "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
      })
      loglevel = 'WARN'
      c = CollectUtils.new(@conf, loglevel)
      c_env = c.export_env()
      prechecklog.info("[Precheck] Check OS parameters...")
      prechecklog.info("[Precheck]    operating system = #{c_env[:os]}")
      prechecklog.info("[Precheck]    kernel version = #{c_env[:kernel]}")
      prechecklog.info("[Precheck] Check td-agent parameters...")
      prechecklog.info("[Precheck]    td-agent conf path = #{c_env[:tdconf_path]}")
      prechecklog.info("[Precheck]    td-agent conf file = #{c_env[:tdconf]}")
      prechecklog.info("[Precheck]    td-agent log path = #{c_env[:tdlog_path]}")
      prechecklog.info("[Precheck]    td-agent log = #{c_env[:tdlog]}")
      if c_env[:tdconf_path] == nil || c_env[:tdconf] == nil
	prechecklog.warn("[Precheck]    can not find td-agent conf path: please run diagtool command with -c /path/to/<td-agent conf file>")
      end
      if c_env[:tdlog_path] == nil || c_env[:tdlog] == nil
        prechecklog.warn("[Precheck]    can not find td-agent log path: please run diagtool command with -l /path/to/<td-agent log file>")
      end
      if c_env[:tdconf_path] != nil && c_env[:tdconf] != nil && c_env[:tdlog_path] != nil && c_env[:tdlog] != nil
	 prechecklog.info("[Precheck] Precheck completed. You can run diagtool command without -c and -l options")
      end
    end

    def run_diagtool()
      @conf[:time] = @time_format
      @conf[:workdir] = @conf[:basedir] + '/' + @time_format
      @conf[:outdir] = @conf[:workdir] + '/output'
      FileUtils.mkdir_p(@conf[:workdir])
      FileUtils.mkdir_p(@conf[:outdir])
      diaglog = @conf[:workdir] + '/diagtool.output'

      @masklog = './mask_' + @time_format + '.json'
      @logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
        "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
      })
      @logger_file = Logger.new(diaglog, formatter: proc {|severity, datetime, progname, msg|
        "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
      })
      diaglogger_info("Parsing command options...")
      diaglogger_info("   Option : Output directory = #{@conf[:basedir]}")
      diaglogger_info("   Option : Mask = #{@conf[:mask]}")
      diaglogger_info("   Option : Word list = #{@conf[:words]}")
      diaglogger_info("   Option : Hash Seed = #{@conf[:seed]}")

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

      diaglogger_info("[Collect] Collecting td-agent gem information...")
      tdgem = c.collect_tdgems()
      diaglogger_info("[Collect] td-agent gem information is stored in #{tdgem}")

      diaglogger_info("[Collect] Collecting config file of OS log...")
      oslog = c.collect_oslog()
      if @conf[:mask] == 'yes'
        diaglogger_info("[Mask] Masking OS log file : #{oslog}...")
        oslog = m.mask_tdlog(oslog, clean = true)
      end
      diaglogger_info("[Collect] config file is stored in #{oslog}")

      diaglogger_info("[Collect] Collecting date/time information...")
      if system('which chronyc > /dev/null 2>&1')
        ntp = c.collect_ntp(command="chrony")
	diaglogger_info("[Collect] date/time information is stored in #{ntp}")
      elsif system('which ntpq > /dev/null 2>&1')
        ntp = c.collect_ntp(command="ntp")
	diaglogger_info("[Collect] date/time information is stored in #{ntp}")
      else
        diaglogger_warn("[Collect] chrony/ntp does not exist. skip collectig date/time information")
      end
      
      ###
      #  Correct OS information
      ###
      @cmd_list.each { |cmd|
	diaglogger_info("[Collect] Collecting command output : command = #{cmd}")
	out = c.collect_cmd_output(cmd)
	if @conf[:mask] == 'yes'
          diaglogger_info("[Mask] Masking netstat file : #{out}...")
          out = m.mask_tdlog(out, clean = true)
        end
	diaglogger_info("[Collect] Collecting command output #{cmd.split[0]} stored in #{out}")
      }
			
      ###
      #  Correct information to be validated
      ###
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
      ulimit = c.collect_cmd_output(cmd="sh -c 'ulimit -n'")
      diaglogger_info("[Collect] ulimit information is stored in #{ulimit}")

      diaglogger_info("[Valid] Validating ulimit information...")
      ret, rec, val = v.valid_ulimit(ulimit)
      if ret == true
        diaglogger_info("[Valid]    ulimit => #{val} is correct (recommendation is >#{rec})")
      else
        diaglogger_warn("[Valid]    ulimit => #{val} is incorrect (recommendation is >#{rec})")
      end

      if @conf[:mask] == 'yes'
	tdconf.each { | file |
	  diaglogger_info("[Mask] Masking td-agent config file : #{file}...")
	  m.mask_tdlog(file, clean = true)
	}
        tdlog.each { | file |
          diaglogger_info("[Mask] Masking td-agent log file : #{file}...")
          filename = file.split("/")[-1]
          if filename.include?(".gz")
            m.mask_tdlog_gz(file, clean = true)
          elsif
            m.mask_tdlog(file, clean = true)
          end
	}
      end
      
      if @conf[:mask] == 'yes'
        diaglogger_info("[Mask] Export mask log file : #{@masklog}")
        m.export_masklog(@masklog)
      end

      tar_file = c.compress_output()
      diaglogger_info("[Collect] Generate tar file #{tar_file}")
    end

    def parse_diagconf(params)
      options = {
        :precheck => '', :basedir => '', :mask => '', :words => [], :wfile => '', :seed => '', :tdconf =>'', :tdlog => ''
      }
      if params[:precheck]
        options[:precheck] = params[:precheck]
      else
        options[:precheck] = false
      end
      if options[:precheck] == false
        if params[:output] != nil
          if Dir.exist?(params[:output])
            options[:basedir] = params[:output]
          else
            raise "output directory '#{basedir}' does not exist"
          end
        else
          raise "output directory '-o' must be specified"
        end
      end
      if params[:mask] == nil
        options[:mask] = 'no'
      else
        if params[:mask] == 'yes' || params[:mask] == 'no'
          options[:mask] = params[:mask]
        else
          raise "invalid arguments '#{params[:mask]}' : input of '-m|--mask' should be 'yes' or 'no'"
        end
      end
      options[:words] = params[:"word-list"] if params[:"word-list"] != nil
      if params[:"word-file"] != nil
        f = params[:"word-file"]
        if File.exist?(f)
          File.readlines(f).each do  |l|
            options[:words].append(l.gsub(/\n/,''))
          end
        else
          raise "#{params[:"word-file"]} : No such file or directory"
        end
      end
      options[:words] = options[:words].uniq 
      options[:seed] = params[:"hash-seed"] if params[:"hash-seed"] != nil
      
      if params[:conf] != nil
        f = params[:conf]
        if File.exist?(f)
	  options[:tdconf] = params[:conf]
        else
          raise "#{params[:conf]} : No such file or directory"
        end
      end

      if params[:log] != nil
        f = params[:log]
        if File.exist?(f)
          options[:tdlog] = params[:log]
        else
          raise "#{params[:log]} : No such file or directory"
        end
      end

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
