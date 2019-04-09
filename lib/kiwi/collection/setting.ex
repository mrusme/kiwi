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
end
