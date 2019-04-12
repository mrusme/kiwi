defmodule Kiwi.Helpers.Settings do
    require Logger
    use Maru.Helper

    params :params_key do
        requires :brightness, type: Integer
        requires :red, type: Integer
        requires :green, type: Integer
        requires :blue, type: Integer
    end
    params :params_event_action_object do
        optional :http, type: Map do
            requires :method, type: :atom, values: [:get, :post, :put, :delete]
            requires :url, type: String
            optional :headers, type: Map
            requires :body, type: String
        end
        optional :led, type: Map do
            requires :frames, type: List do
                requires :keys, type: Map do
                    optional :key_1_in_row_1, type: Map do
                        use :params_key
                    end
                    optional :key_2_in_row_1, type: Map do
                        use :params_key
                    end
                    optional :key_3_in_row_1, type: Map do
                        use :params_key
                    end
                    optional :key_1_in_row_2, type: Map do
                        use :params_key
                    end
                    optional :key_2_in_row_2, type: Map do
                        use :params_key
                    end
                    optional :key_3_in_row_2, type: Map do
                        use :params_key
                    end
                    optional :key_1_in_row_3, type: Map do
                        use :params_key
                    end
                    optional :key_2_in_row_3, type: Map do
                        use :params_key
                    end
                    optional :key_3_in_row_3, type: Map do
                        use :params_key
                    end
                    optional :key_1_in_row_4, type: Map do
                        use :params_key
                    end
                    optional :key_2_in_row_4, type: Map do
                        use :params_key
                    end
                    optional :key_3_in_row_4, type: Map do
                        use :params_key
                    end
                    at_least_one_of [
                        :key_1_in_row_1,
                        :key_2_in_row_1,
                        :key_3_in_row_1,
                        :key_1_in_row_2,
                        :key_2_in_row_2,
                        :key_3_in_row_2,
                        :key_1_in_row_3,
                        :key_2_in_row_3,
                        :key_3_in_row_3,
                        :key_1_in_row_4,
                        :key_2_in_row_4,
                        :key_3_in_row_4
                    ]
                end
                requires :sleep, type: Integer
            end
        end
        at_least_one_of [:http, :led]
    end

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
