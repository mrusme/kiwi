defmodule Kiwi.Application do
    @target Mix.target()

    use Application

    def start(_type, _args) do
        Kiwi.Collection.init_collection()
        Kiwi.Collection.Setting.init_table()
        Kiwi.Collection.Led.init_table()

        opts = [strategy: :one_for_one, name: Kiwi.Supervisor]
        Supervisor.start_link(children(@target), opts)
    end

    def children(:host) do
        [
            {Task.Supervisor, name: Kiwi.Animator.TaskSupervisor},
            Kiwi.Animator,
            {Kiwi.Keyboard, %{}},
            Kiwi.Server
        ]
    end

    def children(_target) do
        [
            {Task.Supervisor, name: Kiwi.Animator.TaskSupervisor},
            Kiwi.Animator,
            {Kiwi.Keyboard, %{}},
            Kiwi.Server
        ]
    end
end
