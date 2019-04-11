defmodule Kiwi.Action do
    require Logger

    def run(%{id: id, object: action_object}, event, state) when is_atom(event) do
        key_name = id
        Logger.debug("Running key #{inspect key_name} event #{inspect event} with state #{inspect state}")

        action_object
        |> Map.get(Atom.to_string(event))
        |> run_action_object_for_event(event, state)
    end

    def run(%{id: id, value: _action_value}, :keydown = event, state) do
        key_name = id
        Logger.debug("Running key #{inspect key_name} event #{inspect event} with state #{inspect state}")
        state
    end

    def run(%{id: id, value: _action_value}, :keyup = event, state) do
        key_name = id
        Logger.debug("Not running key #{inspect key_name} event #{inspect event} with state #{inspect state} because it's a simple :value action, which only runs on :keydown!")
        state
    end

    def run_action_object_for_event(%{} = event_action_object, event, state) do
        Logger.debug("Running action object for event: #{inspect event_action_object} ...")

        pid_http = spawn fn ->
            event_action_object
            |> Map.get("http")
            |> run_action_http(event, state)
        end

        event_action_object
        |> Map.get("led")
        |> run_action_led(event, state)
    end

    def run_action_object_for_event(nil, _event, state) do
        Logger.debug("No event handler available in action object!")

        state
    end

    def run_action_http(%{"method" => method_string, "url" => url, "headers" => headers_object, "body" => body}, _event, state) do
        Logger.debug("Found http action within event action object, running ...")
        headers = for  {k, v}  <-  headers_object  do {k, v} end
        Logger.debug("HTTP request with headers: #{inspect headers}")
        method = String.to_existing_atom(method_string)
        Logger.debug("HTTP request with method: #{inspect method}")

        case Mojito.request(method, url, headers, body, []) do
            {:ok, response} ->
                Logger.debug("HTTP request was successful: #{inspect response}")
                state
            err ->
                Logger.error("HTTP request failed: #{inspect err}")
                state
        end
    end

    def run_action_http(nil, _event, state) do
        Logger.debug("No http action within event action object.")

        state
    end

    def run_action_led(%{"frames" => frames}, event, state) do
        Logger.debug("Found led action within event action object, running ...")

        Enum.reduce(frames, state, fn(frame, last_state) ->
            run_action_led_frame(frame, event, last_state)
        end)
    end

    def run_action_led(nil, _event, state) do
        Logger.debug("No led action within event action object.")

        state
    end

    def run_action_led_frame(%{"keys" => keys} = frame, event, state) do
        Logger.debug("Found keys within frame, running ...")

        {:ok, new_ledarray} = state
        |> Map.get(:ledarray)
        |> Kiwi.LedArray.new_from_existing()

        updated_state = (keys
            |> Map.keys
            |> Enum.reduce(%{state | ledarray: new_ledarray}, fn(key_name_str, last_state) ->
                run_action_led_frame_key(key_name_str, Map.get(keys, key_name_str), event, last_state)
            end)
        )

        case frame |> Map.get("sleep") do
            nil ->
                updated_state
            ms ->
                Logger.debug("Waiting for #{inspect ms} ms ...")
                :timer.sleep(ms)
                updated_state
        end
    end

    def run_action_led_frame(nil, _event, state) do
        Logger.error("No keys within frame! Not running.")

        state
    end

    def run_action_led_frame_key(key_name_str, key, _event, state) do
        {_, new_state} = state |> Map.get_and_update(:ledarray,
            fn ledarray ->
                Logger.debug("Updating LED array: #{inspect ledarray} ...")
                {:ok, key_led} = Kiwi.Collection.Led.new(key_name_str, Map.get(key, "brightness"), Map.get(key, "red"), Map.get(key, "green"), Map.get(key, "blue"))
                Logger.debug("Key LED: #{inspect key_led}")
                {:ok, updated_ledarray} = ledarray |> Kiwi.LedArray.set_led(key_led)
                Logger.debug("Updated LED array: #{inspect updated_ledarray}")
                updated_ledarray |> Kiwi.LedArray.display()
                {ledarray, updated_ledarray}
            end)
        Logger.debug("New state: #{inspect new_state}")
        new_state
    end
end
