defmodule Kiwi.Application do
    @target Mix.target()

    use Application

    def start(_type, _args) do
        Kiwi.Collection.Setting.init()

        opts = [strategy: :one_for_one, name: Kiwi.Supervisor]
        Supervisor.start_link(children(@target), opts)
    end

    def children(:host) do
        [
            {Kiwi.Keyboard, %{}},
            Kiwi.Server
        ]
    end

    def children(_target) do
        [
            {Kiwi.Keyboard, %{}},
            Kiwi.Server
        ]
    end
end
