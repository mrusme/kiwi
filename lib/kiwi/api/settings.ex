defmodule Kiwi.Api.Settings do
    require Logger
    use Kiwi.Server
    use Kiwi.Helpers.Response
    helpers Kiwi.Helpers.Settings

    pipeline do
    end

    namespace :settings do
        namespace :keys do
            route_param :id, type: String do
                get do
                    case Kiwi.Collection.Setting.findOne(params[:id]) do
                        {:ok, found_model} -> conn |> resp({:ok, Kiwi.Helpers.Settings.get_params_from_id_value(found_model)})
                        other -> conn |> resp({:error, other})
                    end
                end

                desc "Update Key Setting"
                params do
                    optional :value,  type: String
                    optional :object, type: Map do
                        optional :keydown, type: Map do
                            use :params_event_action_object
                        end
                        optional :keyup, type: Map do
                            use :params_event_action_object
                        end
                        at_least_one_of [:keydown, :keyup]
                    end
                    exactly_one_of [:value, :object]
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
    end
end
