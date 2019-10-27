require "crotest"
require "../src/stal"

REDIS_HOST = ENV.fetch("REDIS_HOST", "localhost")
REDIS_PORT = ENV.fetch("REDIS_PORT", "6379")

# Transform an Array(Resp::Reply) to Array(String) and sort it.
def sort(list)
  source = list.as Array(Resp::Reply)
  result = Array(String).new

  source.each do |item|
    result << item.as String
  end

  result.sort
end

def connect(url : String)
  c = Resp.new(url)
  yield c
ensure
  disconnect(c)
end

def disconnect(c : Nil)
end

def disconnect(c : Resp)
  c.finalize
end
