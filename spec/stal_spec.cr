require "./spec_helper"

before do
  Resp.new("redis://localhost:6379").tap do |c|
    c.call("FLUSHDB")
    c.call("SADD", "foo", "a", "b", "c")
    c.call("SADD", "bar", "b", "c", "d")
    c.call("SADD", "baz", "c", "d", "e")
    c.call("SADD", "qux", "x", "y", "z")
  end
end

describe "Stal" do
  it "should solve set algebra" do
    c = Resp.new("redis://localhost:6379")

    # Example expression
    expr = ["SUNION", "qux", ["SDIFF", ["SINTER", "foo", "bar"], "baz"]]

    assert_equal ["b", "x", "y", "z"], sort(Stal.solve(c, expr))

    # Commands without sub expressions also work
    expr = ["SINTER", "foo", "bar"]

    assert_equal ["b", "c"], sort(Stal.solve(c, expr))

    # Verify there's no keyspace pollution
    assert_equal ["bar", "baz", "foo", "qux"], sort(c.call("KEYS", "*"))
  end
end
