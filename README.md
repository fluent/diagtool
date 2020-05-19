# Fluentd Diagnostic Tool

The diagtool enable users to automate the date collection which is required for trouble shooting. The data collected by diagtool include the configuration and log files of the td-agent and diagnostic information of operating system such as network and memory status and stats. In some cases, configuration and log files contains the security sensitive information, such as IP addresses and Hostname. The diagtool also provides the functions to generate mask on IP addresses, Hostname(in FQDN style) and user defined keywords described in the collected data.   
The scope of data collection:  
- TD Agent information
  - configuration files (*)
  - log files (*)
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
  - network conectivity status/stats(netstat -plan/netstat -s)
  - memory information(/proc/meminfo)
<br>  
(*) The diagtool automatically gather the path of td-agent configuration files and log files from td-agent daemon and use them during data collection. 

## Prerequisite
The diagtool provides support for td-agent based installation running on Linux OS. The td-agent is a stable distribution package of Fluentd.  
The differences between Fluentd and td-agent are described in followed url:  
https://www.fluentd.org/faqs

## Diagtool Installation

```
# gem install fluent-diagtool
Fetching: fileutils-1.0.2.gem (100%)
Successfully installed fileutils-1.0.2
Fetching: json-2.1.0.gem (100%)
Building native extensions. This could take a while...
Successfully installed json-2.1.0
Fetching: fluent-diagtool-0.1.2.gem (100%)
Successfully installed fluent-diagtool-0.1.2
3 gems installed
```

## Usage
```
# diagtool --help
Usage: /usr/local/bin/diagtool -o OUTPUT_DIR -m {yes | no} -w {word1,[word2...]} -f {listfile} -s {hash seed}
    -o, --output DIR                 Output directory (Mandatory)
    -m, --mask yes|no                Enable mask function (Optional : Default=no)
    -w, --word-list word1,word2      Provide a list of user-defined words which will to be masked (Optional : Default=None)
    -f, --word-file listfile         provide a file which describes a List of user-defined words (Optional : Default=None)
    -s, --hash-seed seed             provide a word which will be used when generate the mask (Optional : Default=None)
```
The list of user-defined words can be specified both -e option and -f option.
The format of user-defined words list file specified in -f option should be followed format.
```
# cat word_list_sample
centos8101
centos8102
```
NOTE: When user specified the keywork, only the exact match words will be masked. For instance, when users like to mask words like "nginx1" and "nginx2", users need to specify "nginx1" and "nginx2" respectively and "nginx*" should not work in the tool.

#### Command sample:
```
# diagtool -o /tmp/work1 -w passwd1,passwd2 -f word_list_sample -m yes
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] Parsing command options...
2020-05-12 18:21:19 -0400: [Diagtool] [INFO]    Option : Output directory = /tmp/work1
2020-05-12 18:21:19 -0400: [Diagtool] [INFO]    Option : Mask = yes
2020-05-12 18:21:19 -0400: [Diagtool] [INFO]    Option : Word list = ["passwd1", "passwd2", "centos8101", "centos8102"]
2020-05-12 18:21:19 -0400: [Diagtool] [INFO]    Option : Hash Seed =
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] Initializing parameters...
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect] Loading the environment parameters...
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect]    operating system = CentOS Linux 8 (Core)
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect]    kernel version = Linux 4.18.0-147.el8.x86_64
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect]    td-agent conf path = /etc/td-agent/
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect]    td-agent conf file = td-agent.conf
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect]    td-agent log path = /var/log/td-agent/
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect]    td-agent log = td-agent.log
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect] Collecting log files of td-agent...
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect] log files of td-agent are stored in ["/tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200508.gz", "/tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200509.gz", "/tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200507.gz", "/tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200512", "/tmp/work1/20200512182119/var/log/td-agent/td-agent.log"]
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect] Collecting config file of td-agent...
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect] config file is stored in /tmp/work1/20200512182119/etc/td-agent/td-agent.conf
2020-05-12 18:21:19 -0400: [Diagtool] [INFO] [Collect] Collecting td-agent gem information...
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] td-agent gem information is stored in /tmp/work1/20200512182119/etc/td-agent/tdgem_list.output
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] Collecting config file of OS log...
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Mask] Masking OS log file : /tmp/work1/20200512182119/var/log/messages...
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] config file is stored in /tmp/work1/20200512182119/var/log/messages.mask
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] Collecting OS memory information...
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] config file is stored in /tmp/work1/20200512182119/meminfo.output
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] Collecting date/time information...
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] date/time information is stored in /tmp/work1/20200512182119/ntp_info.output
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Collect] Collecting netstat information...
2020-05-12 18:21:20 -0400: [Diagtool] [INFO] [Mask] Masking netstat file : /tmp/work1/20200512182119/netstat_n.output...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Collect] netstat information is stored in /tmp/work1/20200512182119/netstat_n.output.mask and /tmp/work1/20200512182119/netstat_s.output
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Collect] Collecting systctl information...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Collect] sysctl information is stored in /tmp/work1/20200512182119/etc/sysctl.conf
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid] Validating systctl information...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_somaxconn => 1024 is correct (recommendation is 1024)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_netdev_max_backlog => 5000 is correct (recommendation is 5000)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_rmem_max => 16777216 is correct (recommendation is 16777216)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_wmem_max => 16777216 is correct (recommendation is 16777216)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_wmem => ["4096", "12582912", "16777216"] is correct (recommendation is ["4096", "12582912", "16777216"])
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_rmem => ["4096", "12582912", "16777216"] is correct (recommendation is ["4096", "12582912", "16777216"])
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_max_syn_backlog => 8096 is correct (recommendation is 8096)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_slow_start_after_idle => 0 is correct (recommendation is 0)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_tw_reuse => 1 is correct (recommendation is 1)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_ip_local_port_range => ["10240", "65535"] is correct (recommendation is ["10240", "65535"])
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Collect] Collecting ulimit information...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Collect] ulimit information is stored in /tmp/work1/20200512182119/ulimit_n.output
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid] Validating ulimit information...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Valid]    ulimit => 65536 is correct (recommendation is >65535)
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Masking td-agent config file : /tmp/work1/20200512182119/etc/td-agent/td-agent.conf...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Masking td-agent log file : /tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200508.gz...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Masking td-agent log file : /tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200509.gz...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Masking td-agent log file : /tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200507.gz...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Masking td-agent log file : /tmp/work1/20200512182119/var/log/td-agent/td-agent.log-20200512...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Masking td-agent log file : /tmp/work1/20200512182119/var/log/td-agent/td-agent.log...
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Mask] Export mask log file : ./mask_20200512182119.json
2020-05-12 18:21:22 -0400: [Diagtool] [INFO] [Collect] Generate tar file /tmp/work1/diagout-20200512182119.tar.gz
```
## Mask Function
When run diagtool with mask option, the log of mask is also created in 'mask_{timestamp}.json' file. Users are able to confirm how the mask was generated on each files.  
The diagtool provides hash-seed option with '-s'. When hash-seed is specified, the mask will be generated with original word and hash-seed so that users could use unique mask value.
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
- OS : CentOS 8.1
- Fluentd : td-agent version 3  
  https://docs.fluentd.org/quickstart/td-agent-v2-vs-v3


