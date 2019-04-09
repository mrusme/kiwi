defmodule Kiwi.Api.Settings do
    use Kiwi.Server
    use Kiwi.Helpers.Response

    pipeline do
    end

    namespace :settings do
        route_param :id do
            get do
                case Kiwi.Collection.Setting.findOne(params[:id]) do
                    {:ok, found_model} -> conn |> resp({:ok, found_model})
                    other -> conn |> resp({:error, other})
                end
            end

            desc "Update Setting"
            params do
                requires :value, type: String
            end
            post do
                case struct(Kiwi.Collection.Setting, params) |> Kiwi.Collection.Setting.upsert do
                    :ok -> conn |> resp({:ok, nil})
                    other -> conn |> resp({:error, nil})
                end
            end
        end
    end
end
