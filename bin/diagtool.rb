require 'optparse'
require 'logger'
require '../lib/diagutils'
include Diagtool

logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
})

output_dir = '../output'
mask = 'yes'
exlist= Array.new

opt = OptionParser.new
opt.banner = "Usage: #{$0} -o OUTPUT_DIR -m {yes | no} -e {word1,[word2...]} -f {listfile}"
opt.on('-o','--output DIR', String, 'Output directory (Default=./output)') { |o|
	output_dir = o 
}
opt.on('-m','--mask YES|NO', String, 'Enable mask function (Default=True)') { |m| 
	if m == 'yes' || m == 'no'
		mask = m
	else
		logger.error("Invalid value '#{m}' : -m | --mask should be yes or no")
		exit!
	end
}
opt.on('-e','--exclude-list LIST', Array, 'Provide a list of exclude words which will to be masked (Default=None)') { |e| exlist += e } 
opt.on('-f','--exclude-file FILE', String, 'provide a file which describes a List of exclude words (Default=None)') { |f|
	if File.exist?(f)
		File.readlines(f).each do  |l|
			exlist.append(l.gsub(/\n/,''))
		end
	else
		logger.error("No such file or directory")
		exit!
	end
}
opt.parse(ARGV)
exlist = exlist.uniq

logger.info("Parsing command options...")
logger.info("   Option : Output directory = #{output_dir}")
logger.info("   Option : Mask = #{mask}")
logger.info("   Option : Exclude list = #{exlist}")

logger.info("Initializing parameters...")
node1 = Diagutils.new(output_dir,exlist, 'INFO')

logger.info("Collecting log files of td-agent...")
tdlog = node1.collect_tdlog()
logger.info("log files of td-agent are stored in #{tdlog}")

logger.info("Collecting config file of td-agent...")
tdconf = node1.collect_tdconf()
logger.info("config file is stored in #{tdconf}")

logger.info("Collecting systctl information...")
sysctl = node1.collect_sysctl()
logger.info("sysctl information is stored in #{sysctl}")

logger.info("Collecting date/time information...")
ntp = node1.collect_ntp()
logger.info("date/time information is stored in #{ntp}")

logger.info("Collecting ulimit information...")
ulimit = node1.collect_ulimit()
logger.info("ulimit information is stored in #{ulimit}")

if mask == 'yes'
	logger.info("Masking td-agent config file : #{tdconf}...")
	node1.mask_tdconf(tdconf)
	tdlog.each do | file |
		logger.info("Masking td-agent log file : #{file}...")
      		filename = file.split("/")[-1]
		if filename.include?(".gz")
               		node1.mask_tdlog_gz(file)
       		elsif
               		node1.mask_tdlog(file)
       		end
	end
end

tar_file = node1.compress_output()
logger.info("Generate tar file #{tar_file}")



