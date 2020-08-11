require 'optparse'
require './lib/Diagutils'

opt = OptionParser.new
opt.on('-e','--exclude_list', 'exclude list'){|v| p "exclude list = #{v}"}
opt.parse(ARGV)
time = Time.new
p time.strftime("%Y%m%d%0k%M")

include Diagtool
exlist = ['centos8101','centos8102']
node1 = Diagutils.new('./output',exlist)
tdlog = node1.collect_tdlog()
tdconf = node1.collect_tdconf()
sysctl = node1.collect_sysctl()
ntp = node1.collect_ntp()
ulimit = node1.collect_ulimit()
node1.mask_tdconf(tdconf)
tdlog.each do | file |
      filename = file.split("/")[-1]
       if filename.include?(".gz")
               node1.mask_tdlog_gz(file)
       elsif
               node1.mask_tdlog(file)
       end
end
node1.compress_output()



