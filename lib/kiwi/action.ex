defmodule Kiwi.Action do
    require Logger

    def run(%{id: id, object: action_object} = action_map, event, state) when is_atom(event) do
        key_name = id
        Logger.debug("Running key #{inspect key_name} event #{inspect event} with state #{inspect state}")
        case action_object |> Map.get(Atom.to_string(event)) do
            nil ->
                Logger.debug("No event handler available in action object: #{inspect action_object}!")
                state
            event_action_object ->
                Logger.debug("Running action object for event: #{inspect event_action_object} ...")
                run_action_object_for_event(event_action_object, event, state)
        end
    end

    def run_action_object_for_event(%{"http" => %{"method" => method_string, "url" => url, "headers" => headers_object, "body" => body}}, _event, state) do
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

    def run(%{id: id, value: action_value} = action_map, :keydown = event, state) do
        key_name = id
        Logger.debug("Running key #{inspect key_name} event #{inspect event} with state #{inspect state}")
        state |> led_action(key_name)
    end

    def run(%{id: id, value: action_value} = action_map, :keyup = event, state) do
        key_name = id
        Logger.debug("Not running key #{inspect key_name} event #{inspect event} with state #{inspect state} because it's a simple :value action, which only runs on :keydown!")
        state
    end

    def led_action(state, key_name) do
        {_, new_state} = state |> Map.get_and_update(:ledarray,
            fn ledarray ->
                Logger.debug("Updating LED array: #{inspect ledarray} ...")
                {:ok, key_led} = Kiwi.Collection.Led.new(key_name, 255, 255, 255, 255)
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
