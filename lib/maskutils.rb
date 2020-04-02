require 'digest'
require 'fileutils'
require 'logger'
require 'open3'

module Diagtool
    class Maskutils
	    def initialize(exlist, log_level)
		    load_exlist(exlist)
		    @logger = Logger.new(STDOUT, level: log_level, formatter: proc {|severity, datetime, progname, msg|
                        "#{datetime}: [Maskutils] [#{severity}] #{msg}\n"
                    })
		    @logger.debug("Initialize Maskutils: exlit = #{exlist}")
	    end
	    def mask_tdlog(input_file, clean)
                    f = File.open(input_file+'.mask', 'w')
                    File.readlines(input_file).each do |line|
                            line_masked = mask_tdlog_inspector(line)
                            f.puts(line_masked)
                    end
                    f.close
                    FileUtils.rm(input_file) if clean == true
		    return input_file+'.mask'
            end
            def mask_tdlog_gz(input_file, clean)
                    f = File.open(input_file+'.mask', 'w')
                    gunzip_file = input_file+'.mask'+'.tmp'
                    Open3.capture3("gunzip --keep -c #{input_file} > #{gunzip_file}")
                    File.readlines(gunzip_file).each do |line|
                            line_masked = mask_tdlog_inspector(line)
                            f.puts(line_masked)
                    end
                    f.close
                    FileUtils.rm(gunzip_file)
                    FileUtils.rm(input_file) if clean == true
		    return input_file+'.mask'
            end
	    def mask_tdlog_inspector(line)
		i = 0
		contents=[]
		@logger.debug("Input Line: #{line.chomp}")
		@logger.debug("Splitted Line: #{line.split(/\s/)}")
		loop do
			contents[i] = line.split(/\s/)[i].to_s
			@logger.debug("Splitted Line #{i}: #{contents[i]}")
			if contents[i].include?(',')
				contents_s = contents[i].split(',')
				cnt = 0
				loop do
					if contents_s[cnt].include?('://') ## Mask <http/dRuby>://<address:ip/hostname>:<port>
                                        	@logger.debug("   URL Pattern Detected: #{contents_s[cnt]} -> #{mask_url_pattern(contents_s[cnt])}")
                                        	contents_s[cnt] = mask_url_pattern(contents_s[cnt])
                                	elsif contents_s[cnt].include?('=')
                                        	@logger.debug("   Equal Pattern Detected: #{contents_s[cnt]} -> #{mask_equal_pattern(contents_s[cnt])}")
                                        	contents_s[cnt] = mask_equal_pattern(contents_s[cnt])
                                	elsif contents_s[cnt].include?(':') ## Mask <address:ip/hostname>:<port>
                                        	@logger.debug("   Colon Pattern Detected: #{contents_s[cnt]} -> #{mask_colon_pattern(contents_s[cnt])}")
                                        	contents_s[cnt] = mask_colon_pattern(contents_s[cnt])
                                	elsif mask_ipv4_fqdn_exlist(contents_s[cnt])[0]
                                        	@logger.debug("   Direct Pattern Detected: #{contents_s[cnt]} -> #{mask_direct_pattern(contents_s[cnt])}")
                                        	contents_s[cnt] = mask_direct_pattern(contents_s[cnt])
					end
					cnt+=1
					break if cnt >= contents_s.length 
				end
				contents[i] = contents_s.join(',')
			else
				if contents[i].include?('://') ## Mask <http/dRuby>://<address:ip/hostname>:<port>
					@logger.debug("   URL Pattern Detected: #{contents[i]} -> #{mask_url_pattern(contents[i])}")
					contents[i] = mask_url_pattern(contents[i])
				elsif contents[i].include?('=')
					@logger.debug("   Equal Pattern Detected: #{contents[i]} -> #{mask_equal_pattern(contents[i])}")
					contents[i] = mask_equal_pattern(contents[i])
				elsif contents[i].include?(':') ## Mask <address:ip/hostname>:<port>
					@logger.debug("   Colon Pattern Detected: #{contents[i]} -> #{mask_colon_pattern(contents[i])}")
					contents[i] = mask_colon_pattern(contents[i])
				elsif contents[i].include?(',')
					str = contents[i].split(',')
					p str   
				elsif mask_ipv4_fqdn_exlist(contents[i])[0]
					@logger.debug("   Direct Pattern Detected: #{contents[i]} -> #{mask_direct_pattern(contents[i])}")
                       			contents[i] = mask_direct_pattern(contents[i])
				end
			end
			i+=1
			break if i >= line.split(/\,|\s/).length
		end
		line_masked = contents.join(' ')
		@logger.debug("Masked Line: #{line_masked}")
		return line_masked
	    end
	    def mask_direct_pattern(str)
		if str.include?(">")
			str = str.gsub(">",'')
			str_m = mask_ipv4_fqdn_exlist(str)[1]
			str_m << ">"
		elsif str.include?("]")
                        str = str.gsub("]",'')
                        str_m = mask_ipv4_fqdn_exlist(str)[1]
                        str_m << "]"
		else
			str_m = mask_ipv4_fqdn_exlist(str)[1]
		end
		return str_m
	    end	
	    def mask_url_pattern(str)
		url = str.split('://')
             	cnt_url = 0
                loop do
                    	if url[cnt_url].include?(':')
                		address = url[cnt_url].split(':')
                     		cnt_address = 0
                       		loop do
                    			if address[cnt_address].include?("]")
						address[cnt_address] = mask_ipv4_fqdn_exlist(address[cnt_address].gsub(']',''))[1]
                            			address[cnt_address] << "]"
                     			elsif address[cnt_address].include?(">")
                              			address[cnt_address] = mask_ipv4_fqdn_exlist(address[cnt_address].gsub('>',''))[1]
                              			address[cnt_address] << ">"
                        		else
                          			address[cnt_address] = mask_ipv4_fqdn_exlist(address[cnt_address])[1]
                    			end
                        		cnt_address+=1
                        		break if cnt_address >= address.length
                     		end
                    		url[cnt_url] = address.join(':')
              	    	else
                  		if url[cnt_url].include?("]")
                         		url[cnt_url] = mask_ipv4_fqdn_exlist(url[cnt_url].gsub(']',''))[1]
                           		url[cnt_url] << "]"
				elsif url[cnt_url].include?(">")
                          		url[cnt_url] = mask_ipv4_fqdn_exlist(url[cnt_url].gsub('>',''))[1]
                                	url[cnt_url] << ">"
                      		else
                            		url[cnt_url] = mask_ipv4_fqdn_exlist(url[cnt_url])[1]
                        	end
             	    	end
                        cnt_url+=1
                        break if cnt_url >= url.length
          	end
		return url.join('://')
	    end
	    def mask_equal_pattern(str)
		l = str.split('=') ## Mask host=<address:ip/hostname> or bind=<address: ip/hostname>
                l[1] = mask_ipv4_fqdn_exlist(l[1])[1]
                return l.join('=')
	    end
	    def mask_colon_pattern(str)
		end_with_collon = true if str.end_with?(':')
		l = str.split(':')
		i = 0
		loop do
			l[i] = mask_ipv4_fqdn_exlist(l[i])[1]
			i+=1
			break if i >= l.length
		end
		str_m = l.join(':')
		if end_with_collon
			str_m << ":"
		end
                return str_m
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
