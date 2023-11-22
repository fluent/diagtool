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

module Diagtool
  module Windows
    module PlatformSpecificCollectUtils
      def _find_fluentd_info()
        # Not supported yet.
      end

      def _find_fluentbit_info()
        # Not supported yet.
      end

      def _find_os_info()
        # Not supported yet.
        return {}
      end
    end
  end
end
