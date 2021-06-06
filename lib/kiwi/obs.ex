defmodule Kiwi.OBS do
    require Logger
    use WebSockex

    def start_link(url, args  \\ []) do
        WebSockex.start_link url, __MODULE__, args, name: __MODULE__
    end

    def init(state) do
        Logger.debug("Init OBS: #{inspect state}")
        {:ok, state}
    end

    def handle_connect(_conn, state) do
        Logger.info("OBS connected: #{inspect state}")
        {:ok, state}
    end

    def handle_disconnect(%{reason: {:local, reason}}, state) do
        Logger.info("OBS disconnected (local): #{inspect reason}")
        {:ok, state}
    end

    def handle_disconnect(disconnect_map, state) do
        Logger.info("OBS disconnected: #{inspect disconnect_map}")
        super(disconnect_map, state)
    end

    def handle_frame({_type, msg}, state) do
        Logger.info("OBS frame: #{inspect msg} #{inspect state}")

        case Jason.decode(msg) do
            {:ok, obs_event} ->
                Logger.debug(obs_event)
                event_action(obs_event, :sys.get_state(Kiwi.Keyboard))
            {:error, _} ->
                Logger.error("OBS unable to parse msg: #{msg}")
        end

        {:ok, state}
    end

    def event_action(obs_event, state) when is_map(obs_event) do
        case Kiwi.Collection.Setting.all_converted() do
            {:ok, settings} ->
                settings
                |> Enum.filter(fn(setting) ->
                    setting
                    |> Map.get(:object)
                    |> Map.has_key?("obs_events")
                end)
                |> Enum.reduce([], fn(setting, acc) ->
                    setting
                    |> Map.get(:object)
                    |> Map.get("obs_events")
                    |> Enum.filter(fn(event) ->
                        matches = event |> Map.get("match")
                        found_matches = matches
                            |> Enum.filter(fn(match) ->
                                property = match |> Map.get("property")
                                string_value = match |> Map.get("string_value")
                                bool_value = match |> Map.get("bool_value")
                                int_value = match |> Map.get("int_value")

                                case obs_event |> Map.has_key?(property) do
                                    true ->
                                        property_value = obs_event |> Map.get(property)
                                        cond do
                                            property_value == string_value ->
                                                true
                                            property_value == bool_value ->
                                                true
                                            property_value == int_value ->
                                                true
                                            true ->
                                                false
                                        end
                                    false ->
                                        false
                                end
                            end)
                        length(matches) == length(found_matches)
                    end)
                    |> Enum.concat(acc)
                end)
                |> Enum.reduce(state, fn(matching_obs_event, previous_state) ->
                    Kiwi.Action.run_action_object_for_event(matching_obs_event, %{}, previous_state)
                end)
            {:error, other} ->
                Logger.error("OBS unable to get settings: #{other}")
                state
        end
    end

    def send(msg) when is_map(msg) do
        Logger.info("OBS sending message: #{inspect msg}")
        WebSockex.send_frame(__MODULE__, {:text, Jason.encode!(msg)})
    end

    def send(msg) do
        Logger.info("OBS sending message: #{inspect msg}")
        WebSockex.send_frame(__MODULE__, {:text, msg})
    end
end
