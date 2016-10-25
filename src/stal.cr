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

module Stal
  class InvalidCommand < Exception
  end

  COMMANDS = {
    "SDIFF"  => "SDIFFSTORE",
    "SINTER" => "SINTERSTORE",
    "SUNION" => "SUNIONSTORE",
  }

  def self.command(term)
    COMMANDS.fetch(term) do
      raise InvalidCommand.new(term.to_s)
    end
  end

  # Compile expression into Redis commands
  def self.compile(expr : Array, ids, ops)
    result = Array(String).new

    expr.each do |item|
      result << convert(item, ids, ops)
    end

    result
  end

  # Identity function for item.
  def self.convert(item : String, ids, ops)
    item
  end

  # Transform :SDIFF, :SINTER and :SUNION commands
  # into SDIFFSTORE, SINTERSTORE and SUNIONSTORE.
  def self.convert(expr : Array, ids, ops)
    head = expr[0]
    tail = expr[1, expr.size]

    # Key where partial results will be stored
    id = sprintf("stal:%s", ids.size)

    # Keep a reference to clean it up later
    ids.push(id)

    # Translate into command and destination key
    op = [command(head), id]

    # Compile the rest recursively
    op.concat(compile(tail, ids, ops))

    # Append the outermost operation
    ops.push(op)

    return id
  end

  def self.process(expr : Array)
    ids = Array(String).new
    ops = Array(Array(String)).new

    ops.push(compile(expr, ids, ops))

    return {ops, ids}
  end

  # Return commands without any wrapping added by `solve`
  def self.explain(expr : Array)
    process(expr).first
  end

  # Evaluate expression `expr` in the Redis client `c`.
  def self.solve(c, expr : Array)
    ops, ids = process(expr)

    if ops.size == 1
      c.call(ops[0])
    else
      c.queue("MULTI")

      ops.each do |op|
        c.queue(op)
      end

      c.queue(["DEL"].concat(ids))
      c.queue("EXEC")

      (reply(reply(c.commit).last))[-2]
    end
  end

  private def self.reply(result)
    result.as Array(Resp::Reply)
  end
end
