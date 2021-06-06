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
        case Jason.decode(msg) do
            {:ok, event} -> Logger.debug(event)
            {:error, _} -> Logger.error("OBS unable to parse msg: #{msg}")
        end

        {:ok, state}
    end

    def send(msg) do
        Logger.info("OBS sending message: #{inspect msg}")
        WebSockex.send_frame(__MODULE__, {:text, Jason.encode!(msg)})
    end
end
