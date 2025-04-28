defmodule Kiwi.Actinidain do
    def get_binding_from_state(state) when is_map(state) do
        [previous_http_response: state |> Map.get(:previous_http_response)]
    end

    def get(str) when is_binary(str) do
        Regex.named_captures(~r/\<\<\{(?<script>.*)\}\>\>/, str, global: false, multiline: true)
    end

    def exec(%{"script" => script} = script_map, binding) when is_map(script_map) and is_binary(script) and is_list(binding) do
        {retval, _} = Code.eval_string(script, binding)
        {:ok, retval}
    end

    def exec(nil, _binding) do
        {:noscript, nil}
    end

    def sythesize(str, binding) when is_binary(str) and is_list(binding) do
        case get(str) |> exec(binding) do
            {:ok, retval} -> Regex.replace(~r/(\<\<\{.*\}\>\>)/, str, Jason.encode!(retval), global: true, multiline: true)
            {:noscript, _} -> str
        end
    end
end
