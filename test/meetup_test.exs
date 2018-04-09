defmodule MeetupTest do
  use ExUnit.Case
  doctest Meetup

  test "greets the world" do
    assert Meetup.hello() == :world
  end
end
