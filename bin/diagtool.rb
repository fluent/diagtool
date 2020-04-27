require 'optparse'
require 'logger'
require '../lib/CollectUtils'
require '../lib/MaskUtils'
require '../lib/ValidUtils'
require '../lib/DiagUtils'
include Diagtool

params = {}
OptionParser.new do |opt|
        opt.banner = "Usage: #{$0} -o OUTPUT_DIR -m {yes | no} -e {word1,[word2...]} -f {listfile}"
        opt.on('-o','--output DIR', String, 'Output directory (Default=./output)')
        opt.on('-m','--mask yes|no', String, 'Enable mask function (Default=yes)')
        opt.on('-e','--exclude-list word1,word2', Array, 'Provide a list of exclude words which will to be masked (Default=None)')
        opt.on('-f','--exclude-file listfile', String, 'provide a file which describes a List of exclude words (Default=None)')
        opt.on('-s','--hash-seed seed', String, 'provide a word which will be used when generate the mask (Default=None)')
end.parse!(into: params)
puts params
diag = DiagUtils.new(params)
diag.diagtool()


