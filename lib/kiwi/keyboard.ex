defmodule Kiwi.Keyboard do
    require Logger
    use GenServer

    def keys(), do: %{
        key_1_in_row_1: %{pin: 20, led: 1},
        key_2_in_row_1: %{pin: 16, led: 5},
        key_3_in_row_1: %{pin: 26, led: 9},
        key_1_in_row_2: %{pin: 6,  led: 2},
        key_2_in_row_2: %{pin: 12, led: 6},
        key_3_in_row_2: %{pin: 13, led: 10},
        key_1_in_row_3: %{pin: 22, led: 3},
        key_2_in_row_3: %{pin: 24, led: 7},
        key_3_in_row_3: %{pin: 5,  led: 11},
        key_1_in_row_4: %{pin: 17, led: 4},
        key_2_in_row_4: %{pin: 27, led: 8},
        key_3_in_row_4: %{pin: 23, led: 12}
    }

    def all_pins!(), do: Enum.map(keys(), fn {_key_name, key_map} -> key_map |> Map.get(:pin) end)

    def key_name_from_pin!(pin) when is_number(pin), do: (for {key_name, key_map} <- keys(), Map.get(key_map, :pin) == pin, do: key_name) |> Enum.at(0)

    def led_id_from_key_name!(key_name) when is_atom(key_name), do: Kiwi.Keyboard.keys() |> Map.get(key_name) |> Map.get(:led)

    def start_link(args) do
        GenServer.start_link __MODULE__, args, name: __MODULE__
    end

    def init(_state) do
        Logger.debug "Opening GPIOs ..."

        gpios = for pin <- all_pins!() do
            with \
                {:ok, gpio} <- Circuits.GPIO.open(pin, :input),
                :ok <- Circuits.GPIO.set_interrupts(gpio, :both),
                :ok <- Circuits.GPIO.set_pull_mode(gpio, :pullup)
            do
                gpio
            end
        end

        Logger.debug "Opened GPIOs!"

        Logger.debug "Initializing LEDs ..."
        {:ok, ledarray} = Kiwi.LedArray.init()
        ledarray |> Kiwi.LedArray.display()
        Logger.debug "Initialized LEDs!"

        new_state = %{gpios: gpios, ledarray: ledarray}
        Logger.debug "Initializing Animator ..."
        Kiwi.Animator.set_state(new_state)
        Kiwi.Animator.start_task()
        Logger.debug "Initialized Animator!"

        {:ok, new_state}
    end

    def restart_animator() do
        GenServer.cast(__MODULE__, :restart_animator)
    end

    def handle_cast(:restart_animator, %{} = state) do
        Logger.debug("Restarting animator with state: #{inspect state}")

        Kiwi.Animator.stop_task()
        :timer.sleep(1000)
        Kiwi.Animator.set_state(state)
        Kiwi.Animator.start_task()

        {:noreply, state}
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
                key_event(pin, :keydown, state)
            {:circuits_gpio, pin, _, 1} ->
                Logger.debug "Keyup for pin #{inspect pin}"
                key_event(pin, :keyup, state)
            other ->
                Logger.debug "Retrieved other message: #{inspect other}"
                state
        end

        {:noreply, new_state}
    end

    def key_event(pin, event, state) do
        key_name = key_name_from_pin!(pin)
        {_, new_state} = state |> Map.get_and_update(key_name, fn current_value -> {current_value, state_increment_value(current_value)} end)

        case new_state |> Map.get(key_name) do
            received_messages when received_messages > 2 ->
                key_action(key_name, event, new_state)
            _ ->
                Logger.debug "Ignoring event for now."
                new_state
        end
    end

    def key_action(key_name, event, state) do
        key_name_str = Atom.to_string(key_name)
        case Kiwi.Collection.Setting.findOne(key_name_str) do
            {:ok, key_setting} ->
                action_map = Kiwi.Helpers.Settings.get_params_from_id_value(key_setting)
                Logger.debug("Got action map: #{inspect action_map}")
                Kiwi.Action.run(action_map, event, state)
            _ ->
                Logger.info "No key action defined for #{key_name_str}!"
                state
        end
    end
end
