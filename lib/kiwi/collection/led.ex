defmodule Kiwi.Collection.Led do
    require Logger

    defstruct \
        id: 0,
        brightness: 255,
        red: 0,
        green: 0,
        blue: 0
    use Kiwi.Collection

    def init_table() do
        with \
            :ok <- init_mnesia_table([
                type: :ordered_set,
                attributes: Kiwi.Collection.Led.get_collection_keys()
            ])
        do
            :ok
        else
            err ->
                Logger.error "Mnesia has failed, again!"
                Logger.debug "#{inspect err}"
                err
        end
    end

    def new(key_name, brght \\ 255, r \\ 0, g \\ 0, b \\ 0)
    def new(key_name, brght, r, g, b) when is_atom(key_name) do
        led_id = Kiwi.Keyboard.led_id_from_key_name!(key_name)
        {:ok, %Kiwi.Collection.Led{id: led_id, brightness: brght, red: r, green: g, blue: b}}
    end

    def new(key_name, brght, r, g, b) when is_binary(key_name) do
        new(String.to_existing_atom(key_name), brght, r, g, b)
    end
end
