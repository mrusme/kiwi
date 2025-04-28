defmodule Kiwi.Application do
    @target Mix.target()

    use Application

    def start(_type, _args) do
        kiwi = setup_kiwi()

        Kiwi.Collection.init_collection()
        Kiwi.Collection.Setting.init_table()
        Kiwi.Collection.Led.init_table()

        opts = [strategy: :one_for_one, name: Kiwi.Supervisor]
        Supervisor.start_link(children(@target, kiwi), opts)
    end

    def setup_kiwi() do
        case Code.ensure_compiled?(Nerves.Network) do
            true ->
                kiwi = case File.read("/boot/kiwi.txt") do
                    {:ok, content} ->
                        Regex.scan(~r/NERVES_NETWORK_([A-Z_]+)=(.*)/, content)
                        |> Enum.map(fn(cfg) ->
                            %{
                                cfg
                                |> Enum.at(1)
                                |> String.to_atom()
                                => cfg
                                |> Enum.at(2)
                            }
                        end)
                        |> Enum.reduce(fn(cfg, prev) ->
                            Map.merge(prev, cfg)
                        end)
                    {:error, _} ->
                        %{
                            KEY_MGMT: (System.get_env("NERVES_NETWORK_KEY_MGMT")||"WPA-PSK"),
                            SSID: System.get_env("NERVES_NETWORK_SSID"),
                            PSK: System.get_env("NERVES_NETWORK_PSK"),
                            OBS_SOCKET: System.get_env("NERVES_NETWORK_OBS_SOCKET"),
                        }
                end

                Nerves.Network.setup "wlan0", ssid: kiwi[:SSID], key_mgmt: kiwi[:KEY_MGMT], psk: kiwi[:PSK]

                kiwi
            false ->
                %{
                    OBS_SOCKET: System.get_env("NERVES_NETWORK_OBS_SOCKET"),
                }
        end
    end

    def children(_target, %{OBS_SOCKET: nil} = _kiwi) do
        [
            {Task.Supervisor, name: Kiwi.Animator.TaskSupervisor},
            Kiwi.Animator,
            {Kiwi.Keyboard, %{}},
            Kiwi.Server
        ]
    end

    def children(_target, %{OBS_SOCKET: obs_socket} = _kiwi) do
        [
            {Task.Supervisor, name: Kiwi.Animator.TaskSupervisor},
            Kiwi.Animator,
            {Kiwi.Keyboard, %{}},
            {Kiwi.OBS, obs_socket},
            Kiwi.Server
        ]
    end
end
