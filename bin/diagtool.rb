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

require 'optparse'
require '../lib/collectutils'
require '../lib/maskutils'
require '../lib/validutils'
require '../lib/diagutils'
include Diagtool

params = {}
OptionParser.new do |opt|
        opt.banner = "Usage: #{$0} -o OUTPUT_DIR -m {yes | no} -e {word1,[word2...]} -f {listfile} -s {hash seed}"
        opt.on('-o','--output DIR', String, 'Output directory (Default=./output)')
        opt.on('-m','--mask yes|no', String, 'Enable mask function (Default=yes)')
        opt.on('-e','--exclude-list word1,word2', Array, 'Provide a list of exclude words which will to be masked (Default=None)')
        opt.on('-f','--exclude-file listfile', String, 'provide a file which describes a List of exclude words (Default=None)')
        opt.on('-s','--hash-seed seed', String, 'provide a word which will be used when generate the mask (Default=None)')
end.parse!(into: params)
diag = DiagUtils.new(params)
diag.diagtool()


