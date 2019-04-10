defmodule Kiwi.Helpers.Settings do
    require Logger

    def get_id_value_from_params(%{id: id, value: val}) do
        %{id: id, value: Jason.encode!(%{__value__: val})}
    end

    def get_id_value_from_params(%{id: id, object: obj}) do
        %{id: id, value: Jason.encode!(%{__object__: obj})}
    end

    def get_params_from_id_value(%Kiwi.Collection.Setting{id: id, value: val}) do
        interim_obj = Jason.decode!(val)
        former_value = Map.get(interim_obj, "__value__")
        formver_object = Map.get(interim_obj, "__object__")
        cond do
            former_value != nil -> %{id: id, value: former_value}
            formver_object != nil -> %{id: id, object: formver_object}
            true -> %{}
        end
    end
end
