require './lib/Diagutils'

node1 = Diagutils.new()
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



