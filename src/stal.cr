# Copyright (c) 2016 Michel Martens
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
require "resp"
require "json"

module Stal
  macro with_file(filename, command)
    {% dir = system("dirname", __FILE__).strip %}
    {{ system(command, dir + "/" + filename).stringify }}
  end

  LUA = {
    src: with_file("stal/stal.lua", "cat"),
    sha: with_file("stal/stal.lua", "shasum").split(' ').first,
  }

  # Evaluate expression `expr` in the Redis client `c`.
  def self.solve(c, expr : Array)
    begin
      c.call("EVALSHA", LUA[:sha], "0", expr.to_json)
    rescue ex : Exception
      case ex.message
      when /NOSCRIPT/
        c.call("SCRIPT", "LOAD", LUA[:src])
        c.call("EVALSHA", LUA[:sha], "0", expr.to_json)
      else
        raise ex
      end
    end
  end
end
