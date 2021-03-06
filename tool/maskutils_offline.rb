require 'optparse'
require 'logger'
require '../lib/maskutils'

include Diagtool

logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, msg|
  "#{datetime}: [Diagtool] [#{severity}] #{msg}\n"
})
log_level = 'INFO'
input_file = ''
dir = ''
mask = 'yes'
hash_seed = ''
exlist= Array.new

opt = OptionParser.new
opt.banner = "Usage: #{$0} -i INPUT_FILE -m {yes | no} -w {word1,[word2...]} -f {listfile} -s {hash seed}"
opt.on('-i','--input FILE', String, 'Input file') { |i|
	if File.exist?(i)
		input_file = i 
	else
                logger.error("#{i} : No such file or directory")
                exit!
	end
}
opt.on('-d','--directory DIRECTORY', String, 'Directpry of input file') { |d| dir = Dir.glob(d+'/*') }
opt.on('-m','--mask YES|NO', String, 'Enable mask function (Default=True)') { |m| 
	if m == 'yes' || m == 'no'
		mask = m
	else
		logger.error("Invalid value '#{m}' : -m | --mask should be yes or no")
		exit!
	end
}
opt.on('-w','--word-list LIST', Array, 'Provide a list of user-defined words which will to be masked (Default=None)') { |w| exlist += e } 
opt.on('-f','--word-file FILE', String, 'provide a file which describes a List of user-defined words (Default=None)') { |f|
	if File.exist?(f)
		File.readlines(f).each do  |l|
			exlist.append(l.gsub(/\n/,''))
		end
	else
		logger.error("#{f} : No such file or directory")
		exit!
	end
}
opt.on('-s','--hash-seed seed', String, 'provide a word which will be used when generate the mask (Default=None)') { |s| hash_seed = s }
opt.parse(ARGV)
exlist = exlist.uniq
masklog = '/root/work/mask.log'
conf = {
	:exlist => exlist,
	:seed => hash_seed
	}

logger.info("Parsing command options...")
logger.info("   Option : Input file = #{input_file}")
logger.info("   Option : Mask = #{mask}")
logger.info("   Option : Exclude list = #{exlist}")
mask1 = MaskUtils.new(conf, log_level)

if input_file.nil?
	logger.info("Masking td-agent log file : #{input_file}...")
	case File.extname(input_file)
	when ".gz"
        	mask1.mask_tdlog_gz(input_file, clean = false)
	else
        	mask1.mask_tdlog(input_file, clean = false)
	end
else
	dir.each { |f|
		p f
		logger.info("Masking td-agent log file : #{f}...")
		case File.extname(f)
        	when ".gz"
                	mask1.mask_tdlog_gz(f, clean = false)
        	else
                	mask1.mask_tdlog(f, clean = false)
        	end 
	}
end
mask1.export_masklog(masklog)

