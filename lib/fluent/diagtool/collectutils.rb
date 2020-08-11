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

module Diagtool
  class CollectUtils
    def initialize(conf, log_level)
      @logger = Logger.new(STDOUT, level: log_level, formatter: proc {|severity, datetime, progname, msg|
        "#{datetime}: [Collectutils] [#{severity}] #{msg}\n"
      })
      @precheck = conf[:precheck]
      @time_format = conf[:time]
      @basedir = conf[:basedir]
      @workdir = conf[:workdir]
      @outdir = conf[:outdir]			
       
      @tdenv = gen_tdenv()
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
          raise "The path of td-agent log file need to be specified." if conf[:precheck] == false
	end
      end 
      @osenv = gen_osenv()
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
    
    def gen_osenv()
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
    
    def gen_tdenv()
      stdout, stderr, status = Open3.capture3('systemctl cat td-agent')
      env_dict = {}
      if status.success?
	if @precheck == false  # SKip if precheck is true
          File.open(@outdir+'/td-agent_env.output', 'w') do |f|
            f.puts(stdout)
          end
	end  
        stdout.split().each do | l |
          if l.include?('Environment')
            env_dict[l.split('=')[1]] = l.split('=')[2]
          end
      	end
      else
        exe = 'fluentd'
        stdout, stderr, status = Open3.capture3("ps aux | grep #{exe} | grep -v grep")
        line = stdout.split(/\n/)
	log_path = ''
        conf_path = ''
        line.each { |l|
          cmd = l.split.drop(10)
          i = 0
          log_pos = 0
          conf_pos = 0
          if cmd[-1] != '--under-supervisor'
            cmd.each { |c|
              if c.include?("--log") || c.include?("-l")
                log_pos = i + 1
                log_path = cmd[log_pos]
              elsif c.include?("--conf") || c.include?("-c")
                conf_pos = i + 1
                conf_path = cmd[conf_pos]
              end
              i+=1
            }
	  end
	}
        env_dict['FLUENT_CONF'] = conf_path
        env_dict['TD_AGENT_LOG_FILE'] = log_path
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
      target_dir = @workdir+@tdconf_path
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(@tdconf_path+@tdconf, target_dir)
      conf = @workdir+@tdconf_path+@tdconf
      conf_list = []
      conf_list.push target_dir + @tdconf
      File.readlines(conf).each { |line|
      if line.include? '@include'
        f = line.split()[1]
        if f.start_with?(/\//)  # /tmp/work1/b.conf
          if f.include?('*')
            Dir.glob(f).each { |ff|
              conf_inc = target_dir + ff.gsub(/\//,'__')
              FileUtils.cp(ff, conf_inc)
              conf_list.push conf_inc
             }
	  else 
	    conf_inc = target_dir+f.gsub(/\//,'__')
            FileUtils.cp(f, conf_inc)
            conf_list.push  conf_inc
	  end
        else
	  f = f.gsub('./','') if f.include?('./')
          if f.include?('*')
            Dir.glob(@tdconf_path+f).each{ |ff|
              conf_inc = target_dir + ff.gsub(@tdconf_path,'').gsub(/\//,'__')
              FileUtils.cp(ff, conf_inc)
              conf_list.push conf_inc
            }
	  else
            conf_inc = target_dir+f.gsub(/\//,'__')
            FileUtils.cp(@tdconf_path+f, conf_inc)
            conf_list.push  conf_inc
	  end
        end
      end
     }
     return conf_list
    end

    def collect_tdlog()
      target_dir = @workdir+@tdlog_path
      FileUtils.mkdir_p(target_dir)
      Dir.glob(@tdlog_path+@tdlog+'*').each{ |f| 
        FileUtils.cp(f, target_dir)
      }
      return Dir.glob(target_dir+@tdlog+'*')
    end
    
    def collect_sysctl()
      target_dir = @workdir+@sysctl_path
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(@sysctl_path+@sysctl, target_dir)
      return target_dir+@sysctl
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
	@logger.warn("Can not find OS log file in #{oslog} or #{syslog}")
      end
    end

    def collect_syslog()
      target_dir = @workdir+@oslog_path
      FileUtils.mkdir_p(target_dir)
      FileUtils.cp(@oslog_path+@syslog, target_dir)
      return target_dir+@syslog
    end

    def collect_cmd_output(cmd)
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
      return output
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
