defmodule Kiwi.Application do
    @target Mix.target()

    use Application

    def start(_type, _args) do
        setup_wifi()

        Kiwi.Collection.init_collection()
        Kiwi.Collection.Setting.init_table()
        Kiwi.Collection.Led.init_table()

        opts = [strategy: :one_for_one, name: Kiwi.Supervisor]
        Supervisor.start_link(children(@target), opts)
    end

    def setup_wifi() do
        case Code.ensure_compiled?(Nerves.Network) do
            true ->
                wifi = case File.read("/boot/wifi.txt") do
                    {:ok, content} -> Regex.scan(~r/NERVES_NETWORK_([A-Z_]+)=(.*)/, content) |> Enum.map(fn(cfg) -> %{cfg |> Enum.at(1) |> String.to_atom() => cfg |> Enum.at(2)} end) |> Enum.reduce(fn(cfg, prev) -> Map.merge(prev, cfg) end)
                    {:error, _} -> %{KEY_MGMT: (System.get_env("NERVES_NETWORK_KEY_MGMT")||"WPA-PSK"), SSID: System.get_env("NERVES_NETWORK_SSID"), PSK: System.get_env("NERVES_NETWORK_PSK")}
                end

                Nerves.Network.setup "wlan0", ssid: wifi[:SSID], key_mgmt: wifi[:KEY_MGMT], psk: wifi[:PSK]
            false ->
                nil
        end
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
