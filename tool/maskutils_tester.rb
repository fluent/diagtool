require '../lib/MaskUtils'
include Diagtool

#line = 'test01.demo.com,test02.demo.com:8080'
#line = 'text.txt'
#line = 'org.freedesktop.hostname1'
#line = '8.37.0-13.el8'

elist = []
seed = 'test'
conf = {
	:exlist => elist,
	:seed => seed
	}
mask1 = MaskUtils.new(conf, 'DEBUG')
puts mask1.mask_tdlog_inspector(line)
puts mask1.get_masklog()
