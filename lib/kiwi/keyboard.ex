defmodule Kiwi.Keyboard do
    require Logger
    use GenServer

    def keys(), do: %{
        key_1_in_row_1: %{pin: 20},
        key_2_in_row_1: %{pin: 16},
        key_3_in_row_1: %{pin: 26},
        key_1_in_row_2: %{pin: 6},
        key_2_in_row_2: %{pin: 12},
        key_3_in_row_2: %{pin: 13},
        key_1_in_row_3: %{pin: 22},
        key_2_in_row_3: %{pin: 24},
        key_3_in_row_3: %{pin: 5},
        key_1_in_row_4: %{pin: 17},
        key_2_in_row_4: %{pin: 27},
        key_3_in_row_4: %{pin: 23}
    }

    def all_pins(), do: Enum.map(keys(), fn {_key_name, key_map} -> key_map |> Map.get(:pin) end)

    def key_name_from_pin(pin) when is_number(pin), do: (for {key_name, key_map} <- keys(), Map.get(key_map, :pin) == pin, do: key_name) |> Enum.at(0)

    def start_link(args) do
        GenServer.start_link __MODULE__, args, name: __MODULE__
    end

    def init(_state) do
        Logger.debug "Opening GPIOs ..."

        gpios = for pin <- all_pins() do
            with \
                {:ok, gpio} <- Circuits.GPIO.open(pin, :input),
                :ok <- Circuits.GPIO.set_interrupts(gpio, :both),
                :ok <- Circuits.GPIO.set_pull_mode(gpio, :pullup)
            do
                gpio
            end
        end

        Logger.debug "Opened GPIOs!"

        {:ok, %{gpios: gpios}}
    end

    def state_increment_value(value) when is_number(value) do
        value + 1
    end

    def state_increment_value(nil) do
        1
    end

    def handle_info(msg, state) do
        Logger.debug "Handle Info"
        Logger.debug "#{inspect msg}"
        Logger.debug "#{inspect state}"

        new_state = case msg do
            {:circuits_gpio, pin, _, 0} ->
                Logger.debug "Keydown for pin #{inspect pin}"
                key_event(pin, "down", state)
            {:circuits_gpio, pin, _, 1} ->
                Logger.debug "Keyup for pin #{inspect pin}"
                key_event(pin, "up", state)
            other ->
                Logger.debug "Retrieved other message: #{inspect other}"
                state
        end

        {:noreply, new_state}
    end

    def key_event(pin, event, state) do
        key_name = key_name_from_pin(pin)
        {_, new_state} = state |> Map.get_and_update(key_name, fn current_value -> {current_value, state_increment_value(current_value)} end)

        case new_state |> Map.get(key_name) do
            received_messages when received_messages > 2 -> key_action(key_name, event)
            _ -> Logger.debug "Ignoring event for now."
        end

        new_state
    end

    def key_action(key_name, "down") do
        key_name_str = Atom.to_string(key_name)
        case Kiwi.Collection.Setting.findOne(key_name_str) do
            {:ok, key_setting} -> Kiwi.Action.run(Jason.decode!(key_setting.value))
            _ -> Logger.info "No key action found for #{key_name_str}!"
        end
    end

    def key_action(key_name, "up") do
        key_name_str = Atom.to_string(key_name)
        Logger.info "Keyup for #{key_name_str}!"
    end
end
