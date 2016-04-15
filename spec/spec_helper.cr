require "crotest"
require "../src/stal"

# Transform an Array(Resp::Reply) to Array(String) and sort it.
def sort(list)
  source = list as Array(Resp::Reply)
  result = Array(String).new

  source.each do |item|
    result << item as String
  end

  result.sort
end
