defmodule Kiwi.Collection.Led do
    require Logger

    defstruct \
        id: 0,
        brightness: 227,
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

    def new(key_name, brght \\ 227, r \\ 0, g \\ 0, b \\ 0)
    def new(key_name, brght, r, g, b) when is_atom(key_name) do
        led_id = Kiwi.Keyboard.led_id_from_key_name!(key_name)
        {:ok, %Kiwi.Collection.Led{id: led_id, brightness: brght, red: r, green: g, blue: b}}
    end

    def new(key_name, brght, r, g, b) when is_binary(key_name) do
        new(String.to_existing_atom(key_name), brght, r, g, b)
    end

    def brightness(key) when is_map(key) do
        case Map.get(key, "brightness") do
            nil -> 227
            val -> val
        end
    end

    def brightness(nil = key) when is_nil(key) do
        227
    end

    def red(key) when is_map(key) do
        case Map.get(key, "red") do
            nil -> 255
            val -> val
        end
    end

    def red(nil = key) when is_nil(key) do
        255
    end

    def green(key) when is_map(key) do
        case Map.get(key, "green") do
            nil -> 255
            val -> val
        end
    end

    def green(nil = key) when is_nil(key) do
        255
    end

    def blue(key) when is_map(key) do
        case Map.get(key, "blue") do
            nil -> 255
            val -> val
        end
    end

    def blue(nil = key) when is_nil(key) do
        255
    end
end
