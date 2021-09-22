defmodule Cache.CacheAgentTest do
  use ExUnit.Case

  alias Cache.CacheAgent, as: CA

  # NOTE: that the max size of the cache map/tree is hardcoded to 3
  # for our dev/testing/demo purposes. Could pull it from config
  # in reality

  test "all" do
    Cache.CacheAgent.clear_state()

    # Empty at first
    assert CA.get_state() == %{map: %{}, tree: []}
    assert CA.get(:a) == nil

    # Just :a
    CA.put(:a, 100)
    assert match?(%{map: %{a: {100, _}}, tree: [{_, :a}]}, CA.get_state())

    # With new value for a
    CA.put(:a, 101)
    assert match?(%{map: %{a: {101, _}}, tree: [{_, :a}]}, CA.get_state())

    # New value for :b
    CA.put(:b, 200)
    assert match?(
             %{
               map: %{a: {101, _}, b: {200, _}},
               tree: [{_, :a}, {_, :b}]},
             CA.get_state())

    # New one for :a, gets tagged with unique id of 4 now
    CA.put(:a, 103)
    assert match?(
             %{
               map: %{a: {103, _}, b: {200, _}},
               tree: [{_, :b}, {_, :a}]},
             CA.get_state())

    # New value, :c
    CA.put(:c, 300)
    assert match?(
             %{
               map: %{a: {103, _}, b: {200, _}, c: {300, _}},
               tree: [{_, :b}, {_, :a}, {_, :c}]},
             CA.get_state())

    # Replace :c
    CA.put(:c, 301)
    assert match?(
             %{
               map: %{a: {103, _}, b: {200, _}, c: {301, _}},
               tree: [{_, :b}, {_, :a}, {_, :c}]},
             CA.get_state())

    # Replace :a
    CA.put(:a, 104)
    assert match?(
             %{
               map: %{a: {104, _}, b: {200, _}, c: {301, _}},
               tree: [{_, :b}, {_, :c}, {_, :a}]},
             CA.get_state())

    # New key :d, oldest entry :b is evicted first
    CA.put(:d, 400)
    assert match?(
             %{
               map: %{a: {104, _}, c: {301, _}, d: {400, _}},
               tree: [{_, :c}, {_, :a}, {_, :d}]},
             CA.get_state())
  end

end
