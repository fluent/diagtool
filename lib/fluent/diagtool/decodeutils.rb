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

require 'logger'

module Diagtool
  class DecodeUtils
    def initialize
      @logger = Logger.new(STDOUT, formatter: proc {|severity, datetime, progname, message|
        "#{datetime}: [DecodeUtils] [#{severity}] #{message}\n"
      })
    end

    def chunk_id_to_time(chunk_id)
      # See https://github.com/fluent/fluentd/blob/master/lib/fluent/unique_id.rb
      b1 = [chunk_id[0..7]].pack("H*").unpack1("N")
      b2 = [chunk_id[8..15]].pack("H*").unpack1("N")
      timestamp = ((b1 << 32 | b2) >> 12) / 1000 / 1000
      usec = ((b1 << 32 | b2) >> 12) % (1000 * 1000)
      Time.at(timestamp, usec)
    end

    def run(params)
      if params[:decode_chunk_id]
        chunk_id = params[:decode_chunk_id]
        timestamp = chunk_id_to_time(chunk_id)
        @logger.info("#{chunk_id} => #{timestamp.inspect}")
      elsif params[:backup_dir]
        @logger.info("Checking backup directory: #{params[:backup_dir]}")
        min_time = Time.now
        max_time = Time.at(0)
        Dir.glob("#{params[:backup_dir]}/**/*") do |path|
          next unless File.file?(path)
          chunk_id = File.basename(path, File.extname(path))
          if chunk_id.start_with?("b") or chunk_id.start_with?("q")
            chunk_id = chunk_id[1..]
          end
          timestamp = chunk_id_to_time(chunk_id)
          @logger.info("#{path} => #{timestamp.inspect}")
          if timestamp < min_time
            min_time = timestamp
          end
          if timestamp > max_time
            max_time = timestamp
          end
        end
        @logger.info("Timestamp range: #{min_time} - #{max_time}")
      end
    end
  end
end

