defmodule Kiwi.Collection.Setting do
    require Logger
    @type t :: %__MODULE__{
        id:    String.t(),
        value: String.t()
    }
    defstruct \
        id:    "",
        value: ""

    use Kiwi.Collection

    def init_table() do
        with \
            :ok <- init_mnesia_table()
        do
            :ok
        else
            err ->
                Logger.error "Mnesia has failed, again!"
                Logger.debug "#{inspect err}"
                err
        end
    end
end
