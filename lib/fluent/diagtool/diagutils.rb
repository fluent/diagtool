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

module Diagtool
  ON_WINDOWS = /mingw/.match?(RUBY_PLATFORM)
  def self.windows?
    ON_WINDOWS
  end
end

require 'logger'
require 'fileutils'
require 'fluent/diagtool/collectutils'
require 'fluent/diagtool/maskutils'
require 'fluent/diagtool/validutils'
require 'fluent/diagtool/windows/diagutils' if Diagtool.windows?
include Diagtool

module Diagtool
  class DiagUtils
    # TODO: Consider making the logic of this class more abstract and
    # cutting out the unix-specific logic into a separate module as well.
    # (Currently, very limited features are supported for Windows.
    # In order to reduce impact on the existing logic for Unix-like.
    # only Windows-specific logic is separated into the module, for now.
    # In the future, the implementation of this class should be more abstract.)
    prepend Windows::PlatformSpecificDiagUtils if Diagtool.windows?

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
      if @conf[:type].downcase == "fluentd" && fluent_package?
        @conf[:package_name] = "fluent-package"
        @conf[:service_name] = "fluentd"
      else
        @conf[:package_name] = "td-agent"
        @conf[:service_name] = "td-agent"
      end

      if @conf[:type].downcase == "fluentbit" && fluentbit_package?
        @conf[:package_name] = "fluent-bit"
        @conf[:service_name] = "fluent-bit"
      else
        @conf[:package_name] = "td-agent-bit"
        @conf[:service_name] = "td-agent-bit"
      end
    end
    
    def run_precheck()
      prechecklog = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
        "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
      })
      loglevel = 'WARN'
      c = CollectUtils.new(@conf, loglevel)
      c_env = c.export_env()
      prechecklog.info("[Precheck] Fluentd Type = #{@conf[:type]}")
      prechecklog.info("[Precheck] Check OS parameters...")
      prechecklog.info("[Precheck]    operating system = #{c_env[:os]}")
      prechecklog.info("[Precheck]    kernel version = #{c_env[:kernel]}")
      prechecklog.info("[Precheck] Check #{@conf[:package_name]} parameters...")
      prechecklog.info("[Precheck]    #{@conf[:package_name]} conf path = #{c_env[:tdconf_path]}")
      prechecklog.info("[Precheck]    #{@conf[:package_name]} conf file = #{c_env[:tdconf]}")
      prechecklog.info("[Precheck]    #{@conf[:package_name]} log path = #{c_env[:tdlog_path]}")
      prechecklog.info("[Precheck]    #{@conf[:package_name]} log = #{c_env[:tdlog]}")
      if c_env[:tdconf_path] == nil || c_env[:tdconf] == nil
        prechecklog.warn("[Precheck]    can not find #{@conf[:package_name]} conf path: please run diagtool command with -c /path/to/<#{@conf[:package_name]} conf file>")
      end
      if c_env[:tdlog_path] == nil || c_env[:tdlog] == nil
        prechecklog.warn("[Precheck]    can not find #{@conf[:package_name]} log path: please run diagtool command with -l /path/to/<#{@conf[:package_name]} log file>")
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
      diaglogger_info("[Collect]    #{@conf[:package_name]} conf path = #{c_env[:tdconf_path]}")
      diaglogger_info("[Collect]    #{@conf[:package_name]} conf file = #{c_env[:tdconf]}")
      diaglogger_info("[Collect]    #{@conf[:package_name]} log path = #{c_env[:tdlog_path]}")
      diaglogger_info("[Collect]    #{@conf[:package_name]} log = #{c_env[:tdlog]}")
      m = MaskUtils.new(@conf, loglevel)
      v = ValidUtils.new(loglevel)
							
      diaglogger_info("[Collect] Collecting log files of #{@conf[:package_name]}...")
      case @type
      when 'fluentd'
        tdlog = c.collect_tdlog()
        diaglogger_info("[Collect] log files of #{@conf[:package_name]} are stored in #{tdlog}")
      when 'fleuntbit'
        if tdlog.empty?
          diaglogger_info("FluentBit logs are redirected to the standard output interface ")
          tdlog = ''
        else
          tdlog = c.collect_tdlog()
          diaglogger_info("[Collect] log files of #{@conf[:package_name]} are stored in #{tdlog}")
        end
      end

      diaglogger_info("[Collect] Collecting config file of #{@conf[:package_name]}...")
      tdconf = c.collect_tdconf()
      diaglogger_info("[Collect] config file is stored in #{tdconf}")

      case @type
      when 'fluentd'
        diaglogger_info("[Collect] Collecting #{@conf[:package_name]} gem information...")
        tdgem = c.collect_tdgems()
        diaglogger_info("[Collect] #{@conf[:package_name]} gem information is stored in #{tdgem}")
        gem_info = c.collect_manually_installed_gems(tdgem)
        diaglogger_info("[Collect] #{@conf[:package_name]} gem information (bundled by default) is stored in #{gem_info[:bundled]}")
        diaglogger_info("[Collect] #{@conf[:package_name]} manually installed gem information is stored in #{gem_info[:local]}")
        local_gems = File.read(gem_info[:local]).lines(chomp: true)
        unless local_gems == [""]
          diaglogger_info("[Collect] #{@conf[:package_name]} manually installed gems:")
          local_gems.each do |gem|
            diaglogger_info("[Collect]   * #{gem}")
          end
        end
      when 'fleuntbit'
        # nothing to do!
      end

      diaglogger_info("[Collect] Collecting config file of OS log...")
      oslog = c.collect_oslog()
      if @conf[:mask] == 'yes'
        diaglogger_info("[Mask] Masking OS log file : #{oslog}...")
        oslog = m.mask_tdlog(oslog, clean = true)
      end
      diaglogger_info("[Collect] config file is stored in #{oslog}")

      diaglogger_info("[Collect] Collecting date/time information...")
      if system('which chronyc > /dev/null 2>&1')
        ntp = c.collect_cmd_output(command="chronyc sources")
        diaglogger_info("[Collect] date/time information is stored in #{ntp}")
      elsif system('which ntpq > /dev/null 2>&1')
        ntp = c.collect_cmd_output(command="ntpq -p")
        diaglogger_info("[Collect] date/time information is stored in #{ntp}")
      else
        diaglogger_warn("[Collect] chrony/ntp does not exist. skip collectig date/time information")
      end
      
      ###
      #  Correct OS information
      ###
      @cmd_list.each { |cmd|
        diaglogger_info("[Collect] Collecting command output : command = #{cmd}")
        if system(cmd + '> /dev/null 2>&1')
          out = c.collect_cmd_output(cmd)
          if @conf[:mask] == 'yes'
            diaglogger_info("[Mask] Masking command output file : #{out}...")
            out = m.mask_tdlog(out, clean = true)
          end
          diaglogger_info("[Collect] Collecting command output #{cmd.split[0]} stored in #{out}")
        end
      }
			
      ###
      #  Correct information to be validated
      ###
      diaglogger_info("[Collect] Collecting sysctl information...")
      sysctl = c.collect_cmd_output("sysctl -a")
      diaglogger_info("[Collect] sysctl information is stored in #{sysctl}")
			
      diaglogger_info("[Valid] Validating sysctl information...")
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
          diaglogger_info("[Mask] Masking #{@conf[:package_name]} config file : #{file}...")
          m.mask_tdlog(file, clean = true)
        }
      end

      if @conf[:mask] == 'yes'
        if tdlog != nil
          tdlog.each { | file |
            diaglogger_info("[Mask] Masking #{@conf[:package_name]} log file : #{file}...")
            filename = file.split("/")[-1]
            if filename.include?(".gz")
              m.mask_tdlog_gz(file, clean = true)
            elsif
              m.mask_tdlog(file, clean = true)
            end
          }
        end
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
        :precheck => '', :basedir => '', :type =>'', :mask => '', :words => [], :wfile => '', :seed => '', :tdconf =>'', :tdlog => ''
      }
      ### Parse precheck flag
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
            raise "output directory '#{params[:output]}' does not exist"
          end
        else
          raise "output directory '-o' must be specified"
        end
      end
      ### Parse fluent type
      if params[:type] == 'fluentd' || params[:type] == 'fluentbit'
        options[:type] = params[:type]
      else
        raise "fluentd type '-t' must be specified (fluentd or fluentbit)"
      end
      ### Parse mask flag
      if params[:mask] == nil
        options[:mask] = 'no'
      else
        if params[:mask] == 'yes' || params[:mask] == 'no'
          options[:mask] = params[:mask]
        else
          raise "invalid arguments '#{params[:mask]}' : input of '-m|--mask' should be 'yes' or 'no'"
        end
      end
     
      ### Parse uder-defined keyword list which will be used in the mask function 
      options[:words] = params[:"word-list"] if params[:"word-list"] != nil

      ### Parse uder-defined keyword file which will be used in the mask function 
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

      ### Parse hash seed which will be used in the mask function 
      options[:seed] = params[:"hash-seed"] if params[:"hash-seed"] != nil

      ### Parse the path of fluentd config file
      if params[:conf] != nil
        f = params[:conf]
        if File.exist?(f)
	  options[:tdconf] = params[:conf]
        else
          raise "#{params[:conf]} : No such file or directory"
        end
      end

      ### Parse the path of fluentd log file
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

    def fluent_package?
      File.exist?("/etc/fluent/fluentd.conf") || File.exist?("/opt/fluent/bin/fluentd")
    end

    def fluentbit_package?
      File.exist?("/etc/fluent-bit/fluent-bit.conf") || File.exist?("/opt/fluent-bit/bin/fluent-bit")
    end
  end
end
