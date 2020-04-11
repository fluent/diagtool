require '../lib/maskutils'
include Diagtool

line = 'test01.demo.com,test02.demo.com:8080'
exlist = []
hash_seed = 'test'
mask1 = Maskutils.new(exlist, hash_seed, 'DEBUG')
puts mask1.mask_tdlog_inspector(line)
puts mask1.get_masklog()
