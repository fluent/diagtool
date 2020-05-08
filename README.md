# Diagnostic Tool

The diagnostic tool enable users to collect the data which includes the configuration and log files of the td-agent for problem determination.
In some cases, configuration and log files contains the security sensitive information, such as IP address and Hostname.
The tool has capability to mask the IP address, Hostname and user defined keywords.<br> 
The scope of data collection:<br>
- TD Agent information
  - configuration file (default:/etc/td-agent/td-agent.conf)
  - log files (default:/var/log/td-agent/td-agent.log)
- OS information
  - OS log file
  - OS parameters
    - time/date information
    - user limits
    - kernel network parameters

## Prerequisite


## Usage

### Online Tool
Users can collect configuration/log files and create masked file automatically by running the online tool.
The online tool provides the function to get the file path of configuration and log files by parsing the systemctl.

#### Arguments of online tool:
```
# ruby diagtool.rb --help
Usage: diagtool.rb -o OUTPUT_DIR -m {yes | no} -e {word1,[word2...]} -f {listfile}
    -o, --output DIR                 Output directory (Default=./output)
    -m, --mask yes|no                Enable mask function (Default=yes)
    -e, --exclude-list word1,word2   Provide a list of exclude words which will to be masked (Default=None)
    -f, --exclude-file listfile      provide a file which describes a List of exclude words (Default=None)
    -s, --hash-seed seed             provide a word which will be used when generate the mask (Default=None)
```
The list of exclude keyword which will be mask can be specified both -e option and -f option.
The format of exclude list file specified in -f option should be followed sample.
```
# cat exlist_sample
centos8101
centos8102
```
NOTE: When user specified the keywork, only the exact match words will be masked. For instance, when users like to mask words like "nginx1" and "nginx2", users need to specify "nginx1" and "nginx2" respectively and "nginx*" should not work in the tool.

#### Command sample:
```
# ruby diagtool.rb -m yes -e centos8101,centos8102 -f exlist_sample -o /tmp/work1
{:output_dir=>"/tmp/work1", :mask=>"yes", :exlist=>["centos8101", "centos8102"], :exfile=>"", :seed=>""}
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Parsing command options...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO]    Option : Output directory = /tmp/work1
2020-05-07 15:54:01 -0400: [Diagtool] [INFO]    Option : Mask = yes
2020-05-07 15:54:01 -0400: [Diagtool] [INFO]    Option : Exclude list = ["centos8101", "centos8102"]
2020-05-07 15:54:01 -0400: [Diagtool] [INFO]    Option : Exclude list =
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Initializing parameters...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect] Loading the environment parameters...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect]    operating system = CentOS Linux 8 (Core)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect]    kernel version = Linux 4.18.0-147.el8.x86_64
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect]    td-agent conf path = /etc/td-agent/
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect]    td-agent conf file = td-agent.conf
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect]    td-agent log path = /var/log/td-agent/
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Collect]    td-agent log = td-agent.log
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Collecting log files of td-agent...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] log files of td-agent are stored in ["/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200226.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200228.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200302.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200303.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200304.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200311.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200318.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200319.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200320.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200321.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200322.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200323.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200330.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200331.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200401.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200402.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200403.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200404.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200405.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200406.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200407.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200408.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200409.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200410.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200411.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200423.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200424.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200425.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200426.gz", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200427", "/tmp/work1/20200507155401/var/log/td-agent/td-agent.log"]
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Collecting config file of td-agent...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] config file is stored in /tmp/work1/20200507155401/etc/td-agent/td-agent.conf
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Collecting date/time information...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] date/time information is stored in /tmp/work1/20200507155401/ntp_info.output
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Collecting systctl information...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] sysctl information is stored in /tmp/work1/20200507155401/etc/sysctl.conf
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Validating systctl information...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_somaxconn => 1024 is correct (recommendation is 1024)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_netdev_max_backlog => 5000 is correct (recommendation is 5000)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_rmem_max => 16777216 is correct (recommendation is 16777216)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_core_wmem_max => 16777216 is correct (recommendation is 16777216)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_wmem => ["4096", "12582912", "16777216"] is correct (recommendation is ["4096", "12582912", "16777216"])
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_rmem => ["4096", "12582912", "16777216"] is correct (recommendation is ["4096", "12582912", "16777216"])
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_max_syn_backlog => 8096 is correct (recommendation is 8096)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_slow_start_after_idle => 0 is correct (recommendation is 0)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_tcp_tw_reuse => 1 is correct (recommendation is 1)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    Sysctl: net_ipv4_ip_local_port_range => ["10240", "65535"] is correct (recommendation is ["10240", "65535"])
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Collecting ulimit information...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] ulimit information is stored in /tmp/work1/20200507155401/ulimit_info.output
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Validating ulimit information...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] [Valid]    ulimit => 65536 is correct (recommendation is >65535)
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Masking td-agent config file : /tmp/work1/20200507155401/etc/td-agent/td-agent.conf...
2020-05-07 15:54:01 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200226.gz...
2020-05-07 15:54:02 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200228.gz...
2020-05-07 15:54:02 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200302.gz...
2020-05-07 15:54:02 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200303.gz...
2020-05-07 15:54:02 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200304.gz...
2020-05-07 15:54:02 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200311.gz...
2020-05-07 15:54:02 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200318.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200319.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200320.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200321.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200322.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200323.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200330.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200331.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200401.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200402.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200403.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200404.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200405.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200406.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200407.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200408.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200409.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200410.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200411.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200423.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200424.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200425.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200426.gz...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log-20200427...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Masking td-agent log file : /tmp/work1/20200507155401/var/log/td-agent/td-agent.log...
2020-05-07 15:54:03 -0400: [Diagtool] [INFO] Generate tar file /tmp/work1/diagout-20200507155401.tar.gz
```
#### Mask sample - IP address: ipv4_md5_{md5hash}
```
2020-02-21 19:22:51 -0500 [info]: [output_system_forward] adding forwarding server ipv4_md5_28b515a0b563a5ac476cc331b75963d0:24224
```
#### Mask sample - Hostname address: fqdn_md5_{md5hash}
```
2020-02-22 00:49:35 -0500 [info]: adding match pattern=fqdn_md5_22db84b867029dac7fe37db6b9e1efbe type="forward"
```
#### Mask sample - User defined keywords: exlist_md5_{md5hash}
```
<match exlist_md5_59d1a1c205305f383f55cc245871f89f>
```


### Offline Tool
The offline tool is also provided to generate the mask on single file for non-fluentd environment.
#### Arguments of online tool:
```
# ruby diagtool_offline.rb --help
Usage: diagtool_offline.rb -i INPUT_FILE -m {yes | no} -e {word1,[word2...]} -f {listfile} -s {hash seed}
    -i, --input FILE                 Input file
    -d, --directory DIRECTORY        Directpry of input file
    -m, --mask YES|NO                Enable mask function (Default=True)
    -e, --exclude-list LIST          Provide a list of exclude words which will to be masked (Default=None)
    -f, --exclude-file FILE          provide a file which describes a List of exclude words (Default=None)
    -s, --hash-seed seed             provide a word which will be used when generate the mask (Default=None)
```


## Tested Environment
- OS : CentOS 8.1
- Fluentd : td-agent version 2
  https://docs.fluentd.org/quickstart/td-agent-v2-vs-v3
- FluentBit : (TBD)


