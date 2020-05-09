#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'digest'
require 'fileutils'
require 'logger'
require 'open3'
require 'json'

module Diagtool
	class MaskUtils
		def initialize(conf, log_level)
			load_exlist(conf[:exlist])
		    	@logger = Logger.new(STDOUT, level: log_level, formatter: proc {|severity, datetime, progname, msg|
                        	"#{datetime}: [Maskutils] [#{severity}] #{msg}\n"
                    	})
		    	@logger.debug("Initialize Maskutils: exlit = #{conf[:exlist]}")
			@hash_seed = conf[:seed]
			@id = {
				:fid =>'',
				:lid =>'',
				:cid =>''
			}
			@masklog = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
	    	end
	    	def mask_tdlog(input_file, clean)
			line_id = 0
                	f = File.open(input_file+'.mask', 'w')
                    	File.readlines(input_file).each do |line|
				line = line.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '')   # temporary
				@id[:fid] = input_file
				@id[:lid] = line_id
                     		line_masked = mask_tdlog_inspector(line)
                            	f.puts(line_masked)
				line_id+=1
                    	end
                    	f.close
                    	FileUtils.rm(input_file) if clean == true
		    	return input_file+'.mask'
            	end
            	def mask_tdlog_gz(input_file, clean)
			line_id = 0
			f = File.open(input_file+'.mask', 'w')
                    	gunzip_file = input_file+'.mask'+'.tmp'
                    	Open3.capture3("gunzip --keep -c #{input_file} > #{gunzip_file}")
                    	File.readlines(gunzip_file).each do |line|
				@id[:fid] = input_file
				@id[:lid] = line_id
                        	line_masked = mask_tdlog_inspector(line)
                            	f.puts(line_masked)
				line_id+=1
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
				@id[:cid] = i.to_s
				if contents[i].include?(',')
					contents_s = contents[i].split(',')
					cnt = 0
					loop do
						@id[:cid] = i.to_s + '-' + cnt.to_s
						if contents_s[cnt].include?('://') ## Mask <http/dRuby>://<address:ip/hostname>:<port>
                                        		is_mask, masked_contents = mask_url_pattern(contents_s[cnt])
							if is_mask
								@logger.debug("   URL Pattern Detected: #{contents_s[cnt]} -> #{masked_contents}")
                                        			contents_s[cnt] = masked_contents
							end
                                		elsif contents_s[cnt].include?('=')
							is_mask, masked_contents = mask_equal_pattern(contents_s[cnt])
							if is_mask
                                        			@logger.debug("   Equal Pattern Detected: #{contents_s[cnt]} -> #{masked_contents}")
                                        			contents_s[cnt] = masked_contents
							end
                                		elsif contents_s[cnt].include?(':') ## Mask <address:ip/hostname>:<port>
							is_mask, masked_contents = mask_colon_pattern(contents_s[cnt])
							if is_mask
                                        			@logger.debug("   Colon Pattern Detected: #{contents_s[cnt]} -> #{masked_contents}")
                                        			contents_s[cnt] = masked_contents
							end
       						elsif contents_s[cnt].include?('/') ## Mask <address:ip/hostname>:<port>
							is_mask, masked_contents = mask_slash_pattern(contents_s[cnt])
							if is_mask
                                                        	@logger.debug("   Slash Pattern Detected: #{contents_s[cnt]} -> #{masked_contents}")
                                                        	contents_s[cnt] = masked_contents
							end
                                		else 
							is_mask, masked_contents = mask_direct_pattern(contents_s[cnt])
							if is_mask
                                        			@logger.debug("   Direct Pattern Detected: #{contents_s[cnt]} -> #{masked_contents}")
                                        			contents_s[cnt] = masked_contents
							end
						end
						cnt+=1
						break if cnt >= contents_s.length 
					end
					contents[i] = contents_s.join(',')
				else
					if contents[i].include?('://') ## Mask <http/dRuby>://<address:ip/hostname>:<port>
						is_mask, masked_contents = mask_url_pattern(contents[i])
						if is_mask
							@logger.debug("   URL Pattern Detected: #{contents[i]} -> #{masked_contents}")
							contents[i] = masked_contents
						end
					elsif contents[i].include?('=')
						is_mask, masked_contents = mask_equal_pattern(contents[i])
						if is_mask
							@logger.debug("   Equal Pattern Detected: #{contents[i]} -> #{masked_contents}")
							contents[i] = masked_contents
						end
					elsif contents[i].include?(':') ## Mask <address:ip/hostname>:<port>
						is_mask, masked_contents = mask_colon_pattern(contents[i])
						if is_mask
							@logger.debug("   Colon Pattern Detected: #{contents[i]} -> #{masked_contents}")
							contents[i] = masked_contents
						end
					elsif contents[i].include?('/')
						is_mask, masked_contents = mask_slash_pattern(contents[i])
						if is_mask
							@logger.debug("   Slash Pattern Detected: #{contents[i]} -> #{masked_contents}")
							contents[i] = masked_contents
						end
					else
						is_mask, masked_contents = mask_direct_pattern(contents[i])
						if is_mask
							@logger.debug("   Direct Pattern Detected: #{contents[i]} -> #{masked_contents}")
                       					contents[i] = masked_contents
						end
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
			is_mask = false
			before_mask = ''
			after_mask = ''
			if str.include?(">")
				str = str.gsub(">",'')
				is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(str)
				str_m = after_mask + ">" if is_mask
			elsif str.include?("]")
                        	str = str.gsub("]",'')
				is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(str)
				str_m = after_mask + "]" if is_mask
			else
				is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(str)
				str_m = after_mask if is_mask
			end
			return is_mask, str_m
	    	end	
	    	def mask_url_pattern(str)
			is_mask = false
                        before_mask = ''
                        after_mask = ''
			url = str.split('://')
             		cnt_url = 0
                	loop do
                    		if url[cnt_url].include?(':')
                			address = url[cnt_url].split(':')
                     			cnt_address = 0
                       			loop do
                    				if address[cnt_address].include?("]")
							is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(address[cnt_address].gsub(']',''))
							address[cnt_address] = after_mask + "]" if is_mask
                     				elsif address[cnt_address].include?(">")
							is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(address[cnt_address].gsub('>',''))
							address[cnt_address] = after_mask + ">" if is_mask
                        			else
							is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(address[cnt_address])
							address[cnt_address] = after_mask if is_mask
                    				end
                        			cnt_address+=1
                        			break if cnt_address >= address.length || is_mask == true
                     			end
                    			url[cnt_url] = address.join(':')
              	    		else
                  			if url[cnt_url].include?("]")
						is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(url[cnt_url].gsub(']',''))
                         			url[cnt_url] = after_mask + "]" if is_mask
					elsif url[cnt_url].include?(">")
						is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(url[cnt_url].gsub('>',''))
                          			url[cnt_url] = after_mask + ">" if is_mask
                      			else
						is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(url[cnt_url])
                            			url[cnt_url] = after_mask if is_mask
                       			end
				end
                        	cnt_url+=1
                        	break if cnt_url >= url.length || is_mask == true
          		end
			str_m = url.join('://')
			str_m << ":" if str.end_with?(':')
			return is_mask, str_m
	    	end
	    	def mask_equal_pattern(str)
			is_mask = false
                        before_mask = ''
                        after_mask = ''
			l = str.split('=') ## Mask host=<address:ip/hostname> or bind=<address: ip/hostname>
			i = 0
			loop do
				is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(l[i])
                		l[i] = after_mask if is_mask
                                i+=1
                                break if i >= l.length || is_mask == true
			end
                	return is_mask, l.join('=')
	    	end
	    	def mask_colon_pattern(str)
			is_mask = false
                        before_mask = ''
                        after_mask = ''
			l = str.split(':')
			i = 0
			loop do
				is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(l[i])
				l[i] = after_mask if is_mask
				i+=1
				break if i >= l.length || is_mask == true
			end
			str_m = l.join(':')
			str_m << ":" if str.end_with?(':')
                	return is_mask, str_m
	    	end
		def mask_slash_pattern(str)
			is_mask = false
                        before_mask = ''
                        after_mask = ''
			l = str.split('/')
                   	i = 0
                    	loop do
				is_mask, before_mask, after_mask = mask_ipv4_fqdn_exlist(l[i])
				l[i] = after_mask if is_mask
                              	i+=1
                             	break if i >= l.length || is_mask == true
                    	end
			str_m = l.join('/')
                        str_m << ":" if str.end_with?(':')
			return is_mask, str_m
		end
	    	def is_ipv4?(str)
			!!(str =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
	    	end
	    	def is_fqdn?(str)
			#!!(str =~ /^\b((?=[a-z0-9-]{1,63}\.)[a-z0-9]+(-[a-z0-9]+)*\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/)
			!!(str =~ /^\b(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.){2,}([A-Za-z]|[A-Za-z][A-Za-z\-]*[A-Za-z]){2,}$/)
			#!!(str =~ /^\b(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)/)
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
			mtype = ''
			is_mask = true
		    	if is_ipv4?(str)
				str_new = str
				mtype = 'ipv4'
		    	elsif is_ipv4?(str.gsub('\"',''))
				str_new = str.gsub('\"','')
				mtype = 'ipv4'
		    	elsif is_ipv4?(str.gsub('\'',''))
				str_new =  str.gsub('\'','')
				mtype = 'ipv4'
		    	elsif is_ipv4?(str.gsub('"',''))
				str_new = str.gsub('"','')
				mtype = 'ipv4'
		    	elsif is_ipv4?(str.gsub(/\"/,''))
				str_new = str.gsub(/\"/,'')
				mtype = 'ipv4'
		    	elsif is_ipv4?(str.gsub('//',''))
				str_new = str.gsub('//','')
				mtype = 'ipv4'
		    	elsif is_fqdn?(str)
				str_new = str
				mtype = 'fqdn'
		    	elsif is_fqdn?(str.gsub('\"',''))
			    	str_new = str.gsub('\"','')
				mtype = 'fqdn'
		    	elsif is_fqdn?(str.gsub('\'',''))
				str_new = str.gsub('\'','')
                                mtype = 'fqdn'
		    	elsif is_fqdn?(str.gsub('"',''))
				str_new = str.gsub('"','')
                                mtype = 'fqdn'
		    	elsif is_fqdn?(str.gsub(/\"/,''))
				str_new = str.gsub(/\"/,'')
				mtype = 'fqdn'
		    	elsif is_fqdn?(str.gsub('//',''))
				str_new = str.gsub('//','')
                                mtype = 'fqdn'
		    	elsif is_exlist?(str)
				str_new = str
                                mtype = 'exlist'
		    	elsif is_exlist?(str.gsub('\"',''))
				str_new = str.gsub('\"','')
				mtype = 'exlist'
		    	elsif is_exlist?(str.gsub('\'',''))
				str_new = str.gsub('\'','')
                                mtype = 'exlist'
		    	elsif is_exlist?(str.gsub('"',''))
				str_new = str.gsub('"','')
                                mtype = 'exlist'
		    	elsif is_exlist?(str.gsub(/\"/,''))
				str_new = str.gsub(/\"/,'')
				mtype = 'exlist'
		    	elsif is_exlist?(str.gsub('//',''))
				str_new = str.gsub('//','')
                                mtype = 'exlist'
		    	else
				str_new = str
				mtype = ''
			    	is_mask = false
		    	end
			if is_mask
				str_hash = mtype + '_md5_' + Digest::MD5.hexdigest(@hash_seed + str_new)
				put_masklog(str_new, str_hash)
			else
				str_hash = str_new
			end
			return is_mask, str_new, str_hash
		end
		def put_masklog(original, hash)
			uid = "Line#{@id[:lid]}-#{@id[:cid]}"
			@masklog[@id[:fid]][uid]['original'] = original
			@masklog[@id[:fid]][uid]['hash'] = hash
		end
		def get_masklog()
			masklog_json = JSON.pretty_generate(@masklog)
			return masklog_json
		end
		def export_masklog(output_file)
			File.open(output_file, 'w') do |f|
                                f.puts(get_masklog())
                        end
		end 
    end
end
