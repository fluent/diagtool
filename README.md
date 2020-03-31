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
# ruby diagtool.rb -h
Usage: diagtool.rb -o OUTPUT_DIR -m {yes | no} -e {word1,[word2...]} -f {listfile}
    -o, --output DIR                 Output directory (Default=./output)
    -m, --mask YES|NO                Enable mask function (Default=True)
    -e, --exclude-list LIST          Provide a list of exclude words which will to be masked (Default=None)
    -f, --exclude-file FILE          provide a file which describes a List of exclude words (Default=None)
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
# ruby diagtool.rb -o ../output -m yes -e centos -f ./exlist_sample
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Parsing command options...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO]    Option : Output directory = ../output
2020-03-31 08:56:17 -0400: [Diagtool] [INFO]    Option : Mask = yes
2020-03-31 08:56:17 -0400: [Diagtool] [INFO]    Option : Exclude list = ["centos", "centos8101", "centos8102"]
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Initializing parameters...
2020-03-31 08:56:17 -0400: [Diagutils] [INFO] Loading the environment parameters...
2020-03-31 08:56:17 -0400: [Diagutils] [INFO]     td-agent conf path = /etc/td-agent/
2020-03-31 08:56:17 -0400: [Diagutils] [INFO]     td-agent conf file = td-agent.conf
2020-03-31 08:56:17 -0400: [Diagutils] [INFO]     td-agent log path = /var/log/td-agent/
2020-03-31 08:56:17 -0400: [Diagutils] [INFO]     td-agent log = td-agent.log
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Collecting log files of td-agent...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] log files of td-agent are stored in ["../output/202003310856/var/log/td-agent/td-agent.log-20200226.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200228.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200302.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200303.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200304.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200311.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200318.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200319.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200320.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200321.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200322.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200323.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200330.gz", "../output/202003310856/var/log/td-agent/td-agent.log-20200331", "../output/202003310856/var/log/td-agent/td-agent.log"]
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Collecting config file of td-agent...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] config file is stored in ../output/202003310856/etc/td-agent/td-agent.conf
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Collecting systctl information...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] sysctl information is stored in ../output/202003310856/etc/sysctl.conf
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Collecting date/time information...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] date/time information is stored in ../output/202003310856/ntp_info.output
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Collecting ulimit information...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] ulimit information is stored in ../output/202003310856/ulimit_info.output
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Masking td-agent config file : ../output/202003310856/etc/td-agent/td-agent.conf...
2020-03-31 08:56:17 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200226.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200228.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200302.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200303.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200304.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200311.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200318.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200319.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200320.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200321.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200322.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200323.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200330.gz...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log-20200331...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Masking td-agent log file : ../output/202003310856/var/log/td-agent/td-agent.log...
2020-03-31 08:56:18 -0400: [Diagtool] [INFO] Generate tar file ../output/diagout-202003310856.tar.gz
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
# ruby diagtool_mask_local.rb -h
Usage: diagtool_mask_local.rb -i INPUT_FILE -m {yes | no} -e {word1,[word2...]} -f {listfile}
    -i, --input FILE                 Input file (Mandatory)
    -m, --mask YES|NO                Enable mask function (Default=True)
    -e, --exclude-list LIST          Provide a list of exclude words which will to be masked (Default=None)
    -f, --exclude-file FILE          provide a file which describes a List of exclude words (Default=None)
```


## Tested Environment
- OS : CentOS 8.1
- Fluentd : td-agent version 1.9.2
- FluentBit : (TBD)


