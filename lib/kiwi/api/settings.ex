defmodule Kiwi.Api.Settings do
    require Logger
    use Kiwi.Server
    use Kiwi.Helpers.Response
    helpers Kiwi.Helpers.Settings

    pipeline do
    end

    namespace :settings do
        get do
            case Kiwi.Collection.Setting.all_converted() do
                {:ok, all_settings} ->
                    conn |> resp({:ok, all_settings})
                {:error, other} ->
                    conn |> resp({:error, other})
            end
        end

        desc "Bulk Upsert Setting"
        params do
            requires :settings, type: List do
                requires :id,     type: String
                optional :value,  type: String
                optional :object, type: Map do
                    use :params_settings_object
                end
                exactly_one_of [:value, :object]
            end
        end
        post do
            case params[:settings]
            |> Enum.map(fn param -> struct(Kiwi.Collection.Setting, Kiwi.Helpers.Settings.get_id_value_from_params(param)) end)
            |> Kiwi.Collection.Setting.upsertMany() do
                :ok -> conn |> resp({:ok, nil})
                other ->
                    Logger.error("#{inspect other}")
                    conn |> resp({:error, nil})
            end
        end

        namespace :keys do
            get do
                all_keys = Kiwi.Keyboard.keys()
                |> Map.keys()
                |> Enum.map(fn key_name ->
                                case Kiwi.Collection.Setting.findOne(key_name) do
                                    {:ok, found_model} -> Kiwi.Helpers.Settings.get_params_from_id_value(found_model)
                                    other -> nil
                                end
                            end)
                |> Enum.filter(fn(found_key) -> !is_nil(found_key) end)
                conn |> resp({:ok, all_keys})
            end

            route_param :id, type: String do
                get do
                    case Kiwi.Collection.Setting.findOne(params[:id]) do
                        {:ok, found_model} -> conn |> resp({:ok, Kiwi.Helpers.Settings.get_params_from_id_value(found_model)})
                        other -> conn |> resp({:error, other})
                    end
                end

                desc "Upsert Key Setting"
                params do
                    optional :object, type: Map do
                        use :params_settings_object
                    end
                end
                post do
                    case struct(Kiwi.Collection.Setting, Kiwi.Helpers.Settings.get_id_value_from_params(params)) |> Kiwi.Collection.Setting.upsert do
                        :ok -> conn |> resp({:ok, nil})
                        other ->
                            Logger.error("#{inspect other}")
                            conn |> resp({:error, nil})
                    end
                end
            end
        end
        namespace :animations do
            route_param :id, type: String do
                get do
                    case Kiwi.Collection.Setting.findOne(params[:id]) do
                        {:ok, found_model} -> conn |> resp({:ok, Kiwi.Helpers.Settings.get_params_from_id_value(found_model)})
                        other -> conn |> resp({:error, other})
                    end
                end

                desc "Upsert Animation Setting"
                params do
                    requires :object, type: Map do
                        requires :frames, type: List do
                            use :params_frame
                        end
                    end
                end
                post do
                    case struct(Kiwi.Collection.Setting, Kiwi.Helpers.Settings.get_id_value_from_params(params)) |> Kiwi.Collection.Setting.upsert do
                        :ok ->
                            Kiwi.Keyboard.restart_animator()
                            conn |> resp({:ok, nil})
                        other ->
                            Logger.error("#{inspect other}")
                            conn |> resp({:error, nil})
                    end
                end
            end
        end
    end
end
