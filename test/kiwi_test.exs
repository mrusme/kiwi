defmodule KiwiTest do
    use ExUnit.Case
    doctest Kiwi

    test "greets the world" do
        assert Kiwi.hello() == :world
    end
end
