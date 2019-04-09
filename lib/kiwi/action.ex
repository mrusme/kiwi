defmodule Kiwi.Action do
    require Logger

    def run(action) when is_map(action) do
        Logger.info "Running action!"
    end
end
