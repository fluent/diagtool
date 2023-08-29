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

require 'fileutils'
require 'open3'
require 'logger'
require 'net/http'
require 'uri'

module Diagtool
  class CollectUtils
    def initialize(conf, log_level)
      @logger = Logger.new(STDOUT, level: log_level, formatter: proc {|severity, datetime, progname, msg|
        "#{datetime}: [Collectutils] [#{severity}] #{msg}\n"
      })
      @precheck = conf[:precheck]
      @type = conf[:type]
      @time_format = conf[:time]
      @basedir = conf[:basedir]
      @workdir = conf[:workdir]
      @outdir = conf[:outdir]
      @tdenv = {
        'FLUENT_CONF' => '',
        'TD_AGENT_LOG_FILE' => ''
      }			
      
      case @type
      when 'fluentd'
        _find_fluentd_info()
      when 'fluentbit'
        _find_fluentbit_info()
      end

      if not conf[:tdconf].empty?
        @tdconf = conf[:tdconf].split('/')[-1]
        @tdconf_path = conf[:tdconf].gsub(@tdconf,'')
      elsif
        if not @tdenv['FLUENT_CONF'].empty?
          @tdconf = @tdenv['FLUENT_CONF'].split('/')[-1]
      	  @tdconf_path = @tdenv['FLUENT_CONF'].gsub(@tdconf,'')
	else
	  raise "The path of td-agent configuration file need to be specified."  if conf[:precheck] == false
	end
      end
      if not conf[:tdlog].empty?
        @tdlog = conf[:tdlog].split('/')[-1]
        @tdlog_path = conf[:tdlog].gsub(@tdlog,'')
      elsif
        if not @tdenv['TD_AGENT_LOG_FILE'].empty?
          @tdlog =  @tdenv['TD_AGENT_LOG_FILE'].split('/')[-1]
          @tdlog_path = @tdenv['TD_AGENT_LOG_FILE'].gsub(@tdlog,'')
        else
          case @type
          when 'fluentd'
            raise "The path of td-agent log file need to be specified." if conf[:precheck] == false
          when 'fluentbit'
            @logger.warn("FluentBit logs are redirected to the standard output interface ")
          end
	      end
      end 
      @osenv = _find_os_info()
      @oslog_path = '/var/log/'
      @oslog = 'messages'
      @syslog = 'syslog'
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
    
    def _find_os_info()
      stdout, stderr, status = Open3.capture3('hostnamectl')
      os_dict = {}
      stdout.each_line { |l|
        s = l.split(":")
        os_dict[s[0].chomp.strip] = s[1].chomp.strip
      }
      if @precheck == false  # SKip if precheck is true
        File.open(@outdir+'/os_env.output', 'w') do |f|
          f.puts(stdout)
        end
      end
      return os_dict
    end
    
    def _find_fluentd_info()
      ### check if the td-agent is run as daemon
      stdout, stderr, status = Open3.capture3('systemctl cat td-agent')
      if status.success?
        if @precheck == false  # SKip if precheck is true
          File.open(@outdir+'/td-agent_env.output', 'w') do |f|
            f.puts(stdout)
          end
        end  
        stdout.split().each do | l |
          if l.include?('Environment')
            @tdenv[l.split('=')[1]] = l.split('=')[2]
          end
        end
      else
        ### check if the td-agent is not run as daemon or run Fluentd with customized script
        stdout, stderr, status = Open3.capture3('ps aux | grep fluentd | grep -v ".*\(grep\|diagtool\)"')
        if status.success?
          line = stdout.split(/\n/)
          line.each do |l|
            cmd = l.split.drop(10)
            i = 0
            if cmd[-1] != '--under-supervisor'
              cmd.each do |c|
                case
                when c == "-c"
                  @tdenv['FLUENT_CONF'] = cmd[i+1]
                when c == "-l"
                  @tdenv['TD_AGENT_LOG_FILE'] = cmd[i+1]
                when c.include?("--conf")
                  @tdenv['FLUENT_CONF'] = c.split("=")[1]
                when c.include?("--log")
                  @tdenv['TD_AGENT_LOG_FILE'] = c.split("=")[1]
                end
                i+=1
              end
            end
          end
        else
          @logger.warn("No Fluentd daemon or proccess running") 
        end
      end
    end
    
    def _find_fluentbit_info()
      ### check if the td-agent-bit is run as daemon
      stdout, stderr, status = Open3.capture3('systemctl cat td-agent-bit')
      if status.success?
        if @precheck == false  # SKip if precheck is true
          File.open(@outdir+'/td-agent-bit_env.output', 'w') do |f|
            f.puts(stdout)
          end
        end
        stdout.split(/\n/).each do | line |
          if line.start_with?("ExecStart")
            cmd = line.split("=")[1]
            i =0
            cmd.split().each do | c |
              case
              when c == "-c"
                @tdenv['FLUENT_CONF'] = cmd.split()[i+1]
              when c == "-l"
                @tdenv['TD_AGENT_LOG_FILE'] = cmd.split()[i+1]
              when c.include?("--conf")
                @tdenv['FLUENT_CONF'] = c.split("=")[1]
              when c.include?("--log")
                @tdenv['TD_AGENT_LOG_FILE'] = c.split("=")[1]
              end
              i+=1
            end
          end
        end
      else
        ### check if the td-agent-bit is not run as daemon or run FluentdBit with customized script 
        stdout, stderr, status = Open3.capture3('ps aux | grep fluent-bit | grep -v ".*\(grep\|diagtool\)"')
        if status.success?
          i = 0
          stdout.split().each do | line |
            case
            when line.include?("--conf")
              @tdenv['FLUENT_CONF'] = line.split("=")[1]
            when line.include?("--log")
              @tdenv['TD_AGENT_LOG_FILE'] = line.split("=")[1]
            when line == "-c"
              @tdenv['FLUENT_CONF'] = stdout.split()[i+1]
            when line == "-l"
              @tdenv['TD_AGENT_LOG_FILE'] = stdout.split()[i+1]
            end
            i+=1
          end
        else
          @logger.warn("No FluentBit daemon or proccess running")
        end
      end
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
      target_dir = @workdir+@tdconf_path
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(@tdconf_path+@tdconf, target_dir)
      conf = @workdir+@tdconf_path+@tdconf
      conf_list = []
      conf_list.push conf
      case @type
      when 'fluentd'
        conf_list = conf_list + _collect_tdconf_include(conf)
      when 'fluentbit'
        conf_list = conf_list + _collect_tdconf_include(conf) + _collect_tdbit_parser(conf) + _collect_tdbit_plugins(conf) 
      end   
      return conf_list
    end

    def _collect_tdconf_include(conf)
      target_dir = @workdir+@tdconf_path
      inc_list = []
      File.readlines(conf).each do |line|
        if line.start_with?('@include')
          l = line.split()[1]
          if l.start_with?('http')
            uri = URI(l)
            inc_http = target_dir + 'http' + uri.path.gsub('/','_')
            File.open(inc_http, 'w') do |f|
              f.puts(Net::HTTP.get(uri))
            end
            inc_list.push inc_http
          else
            if l.start_with?('/')  # /tmp/work1/b.conf
              if l.include?('*')
                Dir.glob(l).each { |ll|
                  inc_conf = target_dir + ll.gsub(/\//,'-')
                  FileUtils.cp(ll, inc_conf)
                  inc_list.push inc_conf
                }
              else 
                inc_conf = target_dir+l.gsub(/\//,'-')
                FileUtils.cp(l, inc_conf)
                inc_list.push inc_conf
              end
            else
              l = l.gsub('./','') if l.include?('./')
              if l.include?('*')
                Dir.glob(@tdconf_path+f).each{ |ll|
                  inc_conf = target_dir + ll.gsub(@tdconf_path,'').gsub(/\//,'-')
                  FileUtils.cp(ll, inc_conf)
                  inc_list.push inc_conf
                }
              else
                inc_conf = target_dir+l.gsub(/\//,'-')
                FileUtils.cp(@tdconf_path+l, inc_conf)
                inc_list.push inc_conf
              end
            end
          end
        end
      end
      return inc_list
    end

    def _collect_tdbit_parser(conf)
      target_dir = @workdir+@tdconf_path
      parser_conf = []
      File.readlines(conf).each do |line|
        if line.strip.start_with?('parsers_file') || line.strip.start_with?('Parsers_File')
          l = line.split()[1]
          if l.start_with?(/\//)  # /tmp/work1/b.conf
            if l.include?('*')
              Dir.glob(l).each { |ll|
                pconf = target_dir + ll.gsub(/\//,'-')
                FileUtils.cp(ll, pconf)
                parser_conf.push(pconf)
              }
            else 
              pconf = target_dir+l.gsub(/\//,'-')
              FileUtils.cp(l, pconf)
              parser_conf.push(pconf)
            end
          else
            l = l.gsub('./','') if l.include?('./')
            if l.include?('*')
              Dir.glob(@tdconf_path+f).each{ |ll|
                pconf = target_dir + ll.gsub(@tdconf_path,'').gsub(/\//,'-')
                FileUtils.cp(ll, pconf)
                parser_conf.push(pconf)
              }
            else
              pconf = target_dir+l.gsub(/\//,'-')
              FileUtils.cp(@tdconf_path+l, pconf)
              parser_conf.push(pconf)
            end
          end
        end
      end  
      return parser_conf
    end

    def _collect_tdbit_plugins(conf)
      target_dir = @workdir+@tdconf_path
      plugins_conf = []
      File.readlines(conf).each do |line|
        if line.strip.start_with?('plugins_file') || line.strip.start_with?('Plugins_File')
          l = line.split()[1]
          if l.start_with?(/\//)  # /tmp/work1/b.conf
            if l.include?('*')
              Dir.glob(l).each { |ll|
                pconf = target_dir + ll.gsub(/\//,'-')
                FileUtils.cp(ll, pconf)
                plugins_conf.push(pconf)
              }
            else 
              pconf = target_dir+l.gsub(/\//,'-')
              FileUtils.cp(l, pconf)
              plugins_conf.push(pconf)
            end
          else
            l = l.gsub('./','') if l.include?('./')
            if l.include?('*')
              Dir.glob(@tdconf_path+f).each{ |ll|
                pconf = target_dir + ll.gsub(@tdconf_path,'').gsub(/\//,'-')
                FileUtils.cp(ll, pconf)
                plugins_conf.push(pconf)
              }
            else
              pconf = target_dir+l.gsub(/\//,'-')
              FileUtils.cp(@tdconf_path+l, pconf)
              plugins_conf.push(pconf)
            end
          end
        end
      end
      return plugins_conf
    end

    def collect_tdlog()
      target_dir = @workdir+@tdlog_path
      FileUtils.mkdir_p(target_dir)
      Dir.glob(@tdlog_path+@tdlog+'*').each{ |f| 
        FileUtils.cp(f, target_dir)
      }
      return Dir.glob(target_dir+@tdlog+'*')
    end
    
    def collect_oslog()
      target_dir = @workdir+@oslog_path
      FileUtils.mkdir_p(target_dir)
      if File.exist? @oslog_path+@oslog
      	FileUtils.cp(@oslog_path+@oslog, target_dir)
      	return target_dir+@oslog
      elsif File.exist? @oslog_path+@syslog
        FileUtils.cp(@oslog_path+@syslog, target_dir)
        return target_dir+@syslog
      else
        @logger.warn("Can not find OS log file in #{@oslog} or #{@syslog}")
      end
    end

    def collect_ntp(command)
      output = @outdir+'/ntp_info.output'
      stdout_date, stderr_date, status_date = Open3.capture3("date")
      stdout_ntp, stderr_ntp, status_ntp = Open3.capture3("chronyc sources") if command == "chrony"
      stdout_ntp, stderr_ntp, status_ntp = Open3.capture3("ntpq -p") if command == "ntp"
      File.open(output, 'w') do |f|
        f.puts(stdout_date)
        f.puts(stdout_ntp)
      end
    end

    def collect_cmd_output(cmd)
      if system(cmd + '> /dev/null 2>&1')
        cmd_name = cmd.gsub(/\s/,'_').gsub(/\//,'-').gsub(',','_')
        output = @outdir+'/'+cmd_name+'.txt'
        stdout, stderr, status = Open3.capture3(cmd)
        if status.success?
          File.open(output, 'w') do |f|
            f.puts(stdout)
          end
        else
          @logger.warn("Command #{cmd} failed due to the following message -  #{stderr.chomp}")
        end
      else
        @logger.warn("Command #{cmd} does not exist -  skip collecting #{cmd} output")
      end
      return output
    end

    def collect_tdgems()
      output = @outdir+'/tdgem_list.output'
      stdout, stderr, status = Open3.capture3("td-agent-gem list | grep fluent")
      File.open(output, 'w') do |f|
        f.puts(stdout)
      end
      return output
    end
    
    def compress_output()
      Dir.chdir(@basedir)
      tar_file = 'diagout-'+@time_format+'.tar.gz'
      stdout, stderr, status = Open3.capture3("tar cvfz #{tar_file} #{@time_format}")
      return @basedir + '/' + tar_file
    end
  end
end
