require 'digest'
require 'fileutils'

module Diagtool
    module Maskutils
	    def mask_tdlog(input_file)
                    f = File.open(input_file+'.mask', 'w')
                    File.readlines(input_file).each do |line|
                            line_masked = mask_tdlog_inspector(line)
                            f.puts(line_masked)
                    end
                    f.close
                    FileUtils.rm(input_file)
            end
            def mask_tdlog_gz(input_file)
                    f = File.open(input_file+'.mask', 'w')
                    gunzip_file = input_file+'.mask'+'.tmp'
                    Open3.capture3("gunzip --keep -c #{input_file} > #{gunzip_file}")
                    File.readlines(gunzip_file).each do |line|
                            line_masked = mask_tdlog_inspector(line)
                            f.puts(line_masked)
                    end
                    f.close
                    FileUtils.rm(gunzip_file)
                    FileUtils.rm(input_file)
            end
	    def mask_tdlog_inspector(line)
		    i = 0
		    contents=[]
		    loop do
			    contents[i] = line.split()[i].to_s
			    if mask_ipv4_fqdn_exlist(contents[i])[0]
				    if contents[i].include?(">")
					    contents[i] = contents[i].gsub(">",'')
					    contents[i] = mask_ipv4_fqdn_exlist(contents[i])[1]
					    contents[i] << ">"
				    else
					    contents[i] = mask_ipv4_fqdn_exlist(contents[i])[1]
				    end
			    end
			    if contents[i].include?('://') ## Mask <http/dRuby>://<address:ip/hostname>:<port>
				    if contents[i].include?('=') ## Mask url=<http/dRuby>://<address:ip/hostname>:<port>
					    l = contents[i].split('=')
					    url = l[1].split(':')
					    address = url[1].split('://')
					    url[1] = '//' + mask_ipv4_fqdn_exlist(address[0])[1]
					    l[1] = url.join(':')
					    contents[i] = l.join('=')
				    else ## Mask <http/dRuby>://<address:ip/hostname>:<port>
					    url = contents[i].split(':')
					    address = url[1].split('://')
					    url[1] = '//' + mask_ipv4_fqdn_exlist(address[0])[1]
					    contents[i] = url.join(':')
				    end
			    elsif contents[i].include?('=')
				    l = contents[i].split('=') ## Mask host=<address:ip/hostname> or bind=<address: ip/hostname>
				    l[1] = mask_ipv4_fqdn_exlist(l[1])[1] 
				    contents[i] = l.join('=')
			    elsif contents[i].include?(':') ## Mask <address:ip/hostname>:<port>
				    l = contents[i].split(':')
				    l[0] = mask_ipv4_fqdn_exlist(l[0])[1]
				    l[0] << ":" if l.length ==1	
				    contents[i] = l.join(':')
			    end
			    i+=1
			    break if i >= line.split().length
		    end
		    line_masked = contents.join(' ')
		    return line_masked
	    end
	    def is_ipv4?(str)
		    !!(str =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
	    end
	    def is_fqdn?(str)
		    !!(str =~ /^\b([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\b/)
	    end
	    def load_exlist(list)
		    @exclude_list = Array.new
		    @exclude_list = list
	    end
	    def is_exlist?(str)
		    value = false
		    exlist = @exclude_list.to_a
		    exlist.each do | l |
			    if str == l
				    value = true
				    break
			    end
		    end
		    return value
	    end
	    def mask_ipv4_fqdn_exlist(str)
		    str = str.to_s
		    if is_ipv4?(str)
			    return true, 'ipv4_md5_'+Digest::MD5.hexdigest(str)
		    elsif is_ipv4?(str.gsub('\"',''))
			    return true, 'ipv4_md5_'+Digest::MD5.hexdigest(str.gsub('\"',''))
		    elsif is_ipv4?(str.gsub('\'',''))
			    return true, 'ipv4_md5_'+Digest::MD5.hexdigest(str.gsub('\'',''))
		    elsif is_ipv4?(str.gsub('"',''))
			    return true, 'ipv4_md5_'+Digest::MD5.hexdigest(str.gsub('"',''))
		    elsif is_ipv4?(str.gsub(/\"/,''))
			    return true, 'ipv4_md5_'+Digest::MD5.hexdigest(str.gsub(/\"/,''))
		    elsif is_ipv4?(str.gsub('//',''))
			    return true, 'ipv4_md5_'+Digest::MD5.hexdigest(str.gsub('//',''))
		    elsif is_fqdn?(str)
			    return true, 'fqdn_md5_'+Digest::MD5.hexdigest(str)
		    elsif is_fqdn?(str.gsub('\"',''))
			    return true, 'fqdn_md5_'+Digest::MD5.hexdigest(str.gsub('\"',''))
		    elsif is_fqdn?(str.gsub('\'',''))
			    return true, 'fqdn_md5_'+Digest::MD5.hexdigest(str.gsub('\'',''))
		    elsif is_fqdn?(str.gsub('"',''))
			    return true, 'fqdn_md5_'+Digest::MD5.hexdigest(str.gsub('"',''))
		    elsif is_fqdn?(str.gsub(/\"/,''))
			    return true, 'fqdn_md5_'+Digest::MD5.hexdigest(str.gsub(/\"/,''))
		    elsif is_fqdn?(str.gsub('//',''))
			    return true, 'fqdn_md5_'+Digest::MD5.hexdigest(str.gsub('//',''))
		    elsif is_exlist?(str)
			    return true, 'exlist_md5_'+Digest::MD5.hexdigest(str)
		    elsif is_exlist?(str.gsub('\"',''))
			    return true, 'exlist_md5_'+Digest::MD5.hexdigest(str.gsub('\"',''))
		    elsif is_exlist?(str.gsub('\'',''))
			    return true, 'exlist_md5_'+Digest::MD5.hexdigest(str.gsub('\'',''))
		    elsif is_exlist?(str.gsub('"',''))
			    return true, 'exlist_md5_'+Digest::MD5.hexdigest(str.gsub('"',''))
		    elsif is_exlist?(str.gsub(/\"/,''))
			    return true, 'exlist_md5_'+Digest::MD5.hexdigest(str.gsub(/\"/,''))
		    elsif is_exlist?(str.gsub('//',''))
			    return true, 'exlist_md5_'+Digest::MD5.hexdigest(str.gsub('//',''))
		    else
			    return false, str
		    end
	    end 
    end
end
