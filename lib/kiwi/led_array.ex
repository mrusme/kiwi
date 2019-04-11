defmodule Kiwi.LedArray do
    require Logger

    defstruct \
        ref: nil,
        led_array: [0,0,0,0,      255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0, 255,0,0,0,      255,255,255,255]

    def padding_start(), do: [0,0,0,0]
    def padding_end(), do: [255,255,255,255]

    def init() do
        {:ok, ref} = Circuits.SPI.open("spidev0.0", [mode: 0, speed_hz: 4000000, delay_us: 500])
        {:ok, %Kiwi.LedArray{ref: ref}}
    end

    def new_from_existing(%Kiwi.LedArray{ref: ref}) do
       {:ok, %Kiwi.LedArray{ref: ref}}
    end

    def set_led(%Kiwi.LedArray{}, %Kiwi.Collection.Led{id: pos}) when is_integer(pos) and (pos < 1 or pos > 12) do
        {:error, "Out of range"}
    end

    def set_led(%Kiwi.LedArray{ref: _ref, led_array: led_array} = ledarray, %Kiwi.Collection.Led{id: pos, brightness: brght, red: r, green: g, blue: b}) when is_integer(pos) and pos >= 1 and pos <= 12 do
        start_index = length(padding_start())
        idx_pos = start_index + ((pos - 1) * 4)
        idx_brght = idx_pos
        idx_b = idx_pos + 1
        idx_g = idx_pos + 2
        idx_r = idx_pos + 3
        # end_index = length(56) - length(padding_end()) - 1

        updated_led_array = led_array
        |> List.replace_at(idx_brght, brght)
        |> List.replace_at(idx_b, b)
        |> List.replace_at(idx_g, g)
        |> List.replace_at(idx_r, r)

        {:ok, %Kiwi.LedArray{ledarray | led_array: updated_led_array}}
    end

    def display(%Kiwi.LedArray{ref: ref, led_array: led_array}) do
        Logger.debug("Displaying LED array: #{inspect led_array}")
        Circuits.SPI.transfer(ref, :binary.list_to_bin(led_array))
    end
end
