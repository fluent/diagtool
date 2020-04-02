require 'optparse'
require 'logger'
require '../lib/maskutils'

include Diagtool

logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
})
log_level = 'DEBUG'
input_file = ''
mask = 'yes'
exlist= Array.new

opt = OptionParser.new
opt.banner = "Usage: #{$0} -i INPUT_FILE -m {yes | no} -e {word1,[word2...]} -f {listfile}"
opt.on('-i','--input FILE', String, 'Input file (Mandatory)') { |i|
	if File.exist?(i)
		input_file = i 
	else
                logger.error("#{i} : No such file or directory")
                exit!
	end
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
		logger.error("#{f} : No such file or directory")
		exit!
	end
}
opt.parse(ARGV)
exlist = exlist.uniq

logger.info("Parsing command options...")
logger.info("   Option : Input file = #{input_file}")
logger.info("   Option : Mask = #{mask}")
logger.info("   Option : Exclude list = #{exlist}")

mask1 = Maskutils.new(exlist, log_level)
logger.info("Masking td-agent log file : #{input_file}...")
case File.extname(input_file)
when ".gz"
        mask1.mask_tdlog_gz(input_file, clean = false)
else
        mask1.mask_tdlog(input_file, clean = false)
end