# Fluentd Diagnostic Tool

Diagtool enables users to automate the date collection which is required for troubleshooting. Diagtool gathers configuration and log files of Fluentd and diagnostic information from an operating system, such as process information and network status. In some cases, configuration and log files contain security sensitive information, such as IP addresses and Hostname. Diagtool has the functions to generate masks on IP addresses, Hostname(in FQDN style) and user defined keywords in the collected files.  
 
The scope of data collection:  
- Fluentd information
  - configuration files
  - log files
  - td-agent environment values
  - installed td-agent-gem list
- OS information
  - OS log file
  - OS parameters
    - OS and kernel version
    - time/date information(ntp -q/chronyc sources)
    - maximum number of file descriptor(ulimit -n)
    - kernel network parameters(sysctl)
  - snapshot of current process(ps)
  - network connectivity status/stats(netstat -plan/netstat -s)
  - memory information(/proc/meminfo)
<br>   

## Prerequisite
Diagtool has been developed for Fluentd(td-agent, fluent-package) and FluentBit(td-agent-bit) running on Linux OS, mainly.
On Windows, it only supports the `installed td-agent-gem list` collection for Fluentd, currently (since v1.0.3).
Diagtool is written in Ruby and Ruby version should be higher than 2.3 for the installation. 
The supported Linux OS is described in the following page:  
https://docs.fluentd.org/quickstart/td-agent-v2-vs-v3-vs-v4

## Diagtool Installation

When you are using td-agent, you can install Diagtool easily with "/usr/sbin/td-agent-gem" command.
```
# /usr/sbin/td-agent-gem install fluent-diagtool
Successfully installed fluent-diagtool-1.0.2
Parsing documentation for fluent-diagtool-1.0.2
Installing ri documentation for fluent-diagtool-1.0.2
Done installing documentation for fluent-diagtool after 0 seconds
1 gem installed
```
When using /usr/sbin/td-agent-gem command, fluent-diagtool is installed under "/opt/td-agent/embedded/lib/ruby/gems/2.4.0/bin/" directory. You can add that directory to $PATH in .bash_profile.  

Otherwise, you can install Diagtool with common gem command. In this case, Ruby version higher than 2.3 might be required to install.
```
# gem install fluent-diagtool
Successfully installed fluent-diagtool-1.0.2
Parsing documentation for fluent-diagtool-1.0.2
Installing ri documentation for fluent-diagtool-1.0.2
Done installing documentation for fluent-diagtool after 0 seconds
1 gem installed
```


## Usage
```
# fluent-diagtool --help
Usage: fluent-diagtool -o OUTPUT_DIR -m {yes | no} -w {word1,[word2...]} -f {listfile} -s {hash seed}
        --precheck                   Run Precheck (Optional)
    -t, --type fluentd|fluentbit     Select the type of Fluentd (Mandatory)
    -o, --output DIR                 Output directory (Mandatory)
    -m, --mask yes|no                Enable mask function (Optional : Default=no)
    -w, --word-list word1,word2      Provide a list of user-defined words which will to be masked (Optional : Default=None)
    -f, --word-file list_file        provide a file which describes a List of user-defined words (Optional : Default=None)
    -s, --hash-seed seed             provide a word which will be used when generate the mask (Optional : Default=None)
    -c, --conf config_file           provide a full path of td-agent configuration file (Optional : Default=None)
    -l, --log log_file               provide a full path of td-agent log file (Optional : Default=None)
```

On Windows, only the `-o, --output DIR` option is supported.

### Precheck

(Not supported on Windows)

In order to run Diagtool correctly, it is required to ensure that Diagtool can obtain the fundamental information of Fluentd. Basically, Diagtool automatically parses the required information from the running Fluentd processes. The precheck option is useful to confirm if Diagtool certainly collects the information as expected. 
The following output example shows the case where Diatool properly collects the required information.

```
# fluent-diagtool --precheck -t fluentd
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck] Fluentd Type = fluentd
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck] Check OS parameters...
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck]    operating system = CentOS Linux 7 (Core)
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck]    kernel version = Linux 3.10.0-1127.10.1.el7.x86_64
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck] Check td-agent parameters...
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck]    td-agent conf path = /etc/td-agent/
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck]    td-agent conf file = td-agent.conf
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck]    td-agent log path = /var/log/td-agent/
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck]    td-agent log = td-agent.log
2020-10-07 21:20:33 +0000: [Diagtool] [INFO] [Precheck] Precheck completed. You can run diagtool command without -c and -l options
```
In some cases, Dialtool, with custom command line options, may fail to identify the path of Fluentd configuration and log files. You need to specify this information manually with “-c” and “-l” options. 
The following example shows pre-check returns failure resulting Diagtool is not able to extract the path of td-agent configuration and log files.
```
# fluent-diagtool --precheck -t fluentd
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck] Check OS parameters...
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck]    operating system = CentOS Linux 8 (Core)
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck]    kernel version = Linux 4.18.0-147.5.1.el8_1.x86_64
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck] Check td-agent parameters...
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck]    td-agent conf path =
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck]    td-agent conf file =
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck]    td-agent log path =
2020-05-28 05:45:14 +0000: [Diagtool] [INFO] [Precheck]    td-agent log =
2020-05-28 05:45:14 +0000: [Diagtool] [WARN] [Precheck]    can not find td-agent conf path: please run diagtool command with -c /path/to/<td-agent conf file>
2020-05-28 05:45:14 +0000: [Diagtool] [WARN] [Precheck]    can not find td-agent log path: please run diagtool command with -l /path/to/<td-agent log file>
```

### Run diagtool
Once the pre-check is completed, you are ready to run the tool. The “-o” is mandatory out of provided options and the output will be generated as a compressed file under the directory specified by “-o“ option.
(*) If the pre-check results mentioned that it is not able to find “td-agent conf path” and “td-agent log path“, you need to use “-c“ and “-l”  respectively to specify the file path manually.

#### Command sample:
```
# fluent-diagtool -t fluentd -o /tmp -w passwd1,passwd2 -m yes
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] Parsing command options...
2020-10-07 21:29:28 +0000: [Diagtool] [INFO]    Option : Output directory = /tmp
2020-10-07 21:29:28 +0000: [Diagtool] [INFO]    Option : Mask = yes
2020-10-07 21:29:28 +0000: [Diagtool] [INFO]    Option : Word list = ["passwd1", "passwd2"]
2020-10-07 21:29:28 +0000: [Diagtool] [INFO]    Option : Hash Seed =
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] Initializing parameters...
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect] Loading the environment parameters...
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect]    operating system = CentOS Linux 7 (Core)
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect]    kernel version = Linux 3.10.0-1127.10.1.el7.x86_64
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect]    td-agent conf path = /etc/td-agent/
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect]    td-agent conf file = td-agent.conf
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect]    td-agent log path = /var/log/td-agent/
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect]    td-agent log = td-agent.log
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect] Collecting log files of td-agent...
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect] Collecting config file of td-agent...
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect] config file is stored in ["/tmp/20201007212928/etc/td-agent/td-agent.conf", "/tmp/20201007212928/etc/td-agent/http_fld_system.conf"]
2020-10-07 21:29:28 +0000: [Diagtool] [INFO] [Collect] Collecting td-agent gem information...
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] td-agent gem information is stored in /tmp/20201007212928/output/tdgem_list.output
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting config file of OS log...
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Mask] Masking OS log file : /tmp/20201007212928/var/log/messages...
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] config file is stored in /tmp/20201007212928/var/log/messages.mask
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting date/time information...
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] date/time information is stored in /tmp/20201007212928/output/chronyc_sources.txt
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting command output : command = ps -eo pid,ppid,stime,time,%mem,%cpu,cmd
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Mask] Masking command output file : /tmp/20201007212928/output/ps_-eo_pid_ppid_stime_time_%mem_%cpu_cmd.txt...
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting command output ps stored in /tmp/20201007212928/output/ps_-eo_pid_ppid_stime_time_%mem_%cpu_cmd.txt.mask
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting command output : command = cat /proc/meminfo
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Mask] Masking command output file : /tmp/20201007212928/output/cat_-proc-meminfo.txt...
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting command output cat stored in /tmp/20201007212928/output/cat_-proc-meminfo.txt.mask
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Collect] Collecting command output : command = netstat -plan
2020-10-07 21:29:29 +0000: [Diagtool] [INFO] [Mask] Masking command output file : /tmp/20201007212928/output/netstat_-plan.txt...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] Collecting command output netstat stored in /tmp/20201007212928/output/netstat_-plan.txt.mask
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] Collecting command output : command = netstat -s
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Mask] Masking command output file : /tmp/20201007212928/output/netstat_-s.txt...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] Collecting command output netstat stored in /tmp/20201007212928/output/netstat_-s.txt.mask
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] Collecting systctl information...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] sysctl information is stored in /tmp/20201007212928/output/sysctl_-a.txt
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid] Validating systctl information...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_core_netdev_max_backlog => 5000 is correct (recommendation is 5000)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_core_rmem_max => 16777216 is correct (recommendation is 16777216)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_core_somaxconn => 1024 is correct (recommendation is 1024)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_core_wmem_max => 16777216 is correct (recommendation is 16777216)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_ip_local_port_range => ["10240", "65535"] is correct (recommendation is ["10240", "65535"])
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_max_syn_backlog => 8096 is correct (recommendation is 8096)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_rmem => ["4096", "12582912", "16777216"] is correct (recommendation is ["4096", "12582912", "16777216"])
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_slow_start_after_idle => 0 is correct (recommendation is 0)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_tw_reuse => 1 is correct (recommendation is 1)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_wmem => ["4096", "12582912", "16777216"] is correct (recommendation is ["4096", "12582912", "16777216"])
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] Collecting ulimit information...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] ulimit information is stored in /tmp/20201007212928/output/sh_-c_'ulimit_-n'.txt
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid] Validating ulimit information...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Valid]    ulimit => 65536 is correct (recommendation is >65535)
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Mask] Masking td-agent config file : /tmp/20201007212928/etc/td-agent/td-agent.conf...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Mask] Masking td-agent config file : /tmp/20201007212928/etc/td-agent/http_fld_system.conf...
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Mask] Export mask log file : ./mask_20201007212928.json
2020-10-07 21:29:30 +0000: [Diagtool] [INFO] [Collect] Generate tar file /tmp/diagout-20201007212928.tar.gz
```

fluent-package (td-agent) on Windows: Fluent Package Command Prompt (Td-agent Command Prompt) with Administrator privilege

```
$ fluent-diagtool -o /opt
2023-11-21 12:46:08 +0900: [Diagtool] [INFO] Parsing command options...
2023-11-21 12:46:08 +0900: [Diagtool] [INFO]    Option : Output directory = /opt
2023-11-21 12:46:08 +0900: [Diagtool] [INFO] Initializing parameters...
2023-11-21 12:46:08 +0900: [Diagtool] [INFO] [Collect] Collecting fluent-package gem information...
2023-11-21 12:46:10 +0900: [Diagtool] [INFO] [Collect] fluent-package gem information is stored in /opt/20231121124608/output/tdgem_list.output
2023-11-21 12:46:10 +0900: [Diagtool] [INFO] [Collect] fluent-package gem information (bundled by default) is stored in /opt/20231121124608/output/gem_bundled_list.output
2023-11-21 12:46:10 +0900: [Diagtool] [INFO] [Collect] fluent-package manually installed gem information is stored in /opt/20231121124608/output/gem_local_list.output
2023-11-21 12:46:10 +0900: [Diagtool] [INFO] [Collect] fluent-package manually installed gems:
2023-11-21 12:46:10 +0900: [Diagtool] [INFO] [Collect]   * fluent-plugin-forest
```

#### The "@include" directive in td-agent configuration file
The "@include" directive is a function to reuse configuration defined in other configuration files. Diagtool reads Fluentd configuration and gathers the files described in "@include" directive as well. The details of "@include" directive are described in followed page:  
https://docs.fluentd.org/configuration/config-file#6-re-use-your-config-the-include-directive

#### User defined words to be masked 
The user-defined words can be specified both -e option and -f option and the words are merged when both options are selected.
The format of user-defined words list file specified in -f option should be followed format.
```
# cat word_list_sample
centos8101
centos8102
```
NOTE: When user specified the keywork, only the exact match words will be masked. For instance, when users like to mask words like "nginx1" and "nginx2", users need to specify "nginx1" and "nginx2" respectively and "nginx*" should not work in the tool.

#### Mask Function
When run Diagtool with the mask option, the log of mask is also created in 'mask_{timestamp}.json' file. Users are able to confirm how the mask was generated on each file.  
The diagtool provides a hash-seed option with '-s'. When hash-seed is specified, the mask will be generated with the original word and hash-seed so that users could use a unique mask value.
#### Mask sample - IP address: IPv4_{md5hash}
```
    "Line112-8": {
      "original": "12.167.151.1",
      "mask": "IPv4_69c29ed8d9d370ac12d53ee0c34a5668"
    },
```
#### Mask sample - Hostname address: FQDN_{md5hash}
```
    "Line0-10": {
      "original": "www.rsyslog.com",
      "mask": "FQDN_fef1c6ae5d66c6de1e395b2010777be5"
    },
```
#### Mask sample - User defined keywords: Word_{md5hash}
```
    "Line2-4": {
      "original": "centos8101",
      "mask": "Word_5160bd119ec593cf4bd34fb4cb855041"
    },

```

## Tested Environment
- OS : CentOS 8.1 / Ubuntu 20.04 / Windows Home 10
- Fluentd : td-agent version 3/4
  https://docs.fluentd.org/quickstart/td-agent-v2-vs-v3-vs-v4
- Fluentd : fluent-package version 5
  https://docs.fluentd.org/quickstart/fluent-package-v5-vs-td-agent
