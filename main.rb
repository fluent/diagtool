require './lib/diag'

node1 = Diagtool.new()
tdlog = node1.collect_tdlog()
tdconf = node1.collect_tdconf()
sysctl = node1.collect_sysctl()
ntp = node1.collect_ntp()
ulimit = node1.collect_ulimit()
#tdlog.each do | file |
#	filename = file.split("/")[-1]
#        if filename.include?(".gz")
#		node1.mask_tdlog_gz(file)
#	elsif
#		p filename
#		node1.mask_tdlog(file)
#	end
#end

test = Diagtool.new()
#line = '2020-02-26 19:10:31 -0500 [warn] #0 failed to flush the buffer. retry_time=0 next_retry_seconds=2020-02-26 19:10:32 -0500 chunk="59f838c7b432e47585ad3028384d79eb" error_class=Errno::ECONNREFUSED error="Connection refused - connect(2) for \"192.168.56.12\" port 24224"'
line = '2020-02-26 19:10:29 -0500 [info] #0 adding forwarding server \'192.168.56.12:24224\' host=ipv4_md5_28b515a0b563a5ac476cc331b75963d0 port=24224 weight=60 plugin_id="object:3fefc3f961c0"'

#test.mask_tdlog('/root/td-agent.log-20200226')

p line
i = 0
contents=[]
loop do
	contents[i] = line.split()[i]
	if contents[i].include? ":"
		l = contents[i].split(":")
		p l[0].gsub('\''){ '' }
		l[0] = 'ipv4_md5_'+Digest::MD5.hexdigest(l[0].gsub('\''){ '' }) if test.is_ipv4?(l[0].gsub('\''){ '' })
                l[0] = 'fqdn_md5_'+Digest::MD5.hexdigest(l[0].gsub('\"'){ '' }) if test.is_fqdn?(l[0].gsub('\"'){ '' })
                p l[0]
		#contents[i] = l.join(":")
		#p contents[i]
		#p contents[i].gsub('\"'){ '' }
		#p contents[i].gsub('\"'){ '' }if test.is_ipv4?(contents[i].gsub('\"'){ '' })
	end
	i+=1
	break if i >= line.split().length
end

#line.split()
#p test.mask_tdlog_inspector(line)

