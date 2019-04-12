defmodule Kiwi.Api do
    require Logger
    use Kiwi.Server
    use Kiwi.Helpers.Response

    before do
        plug Plug.Logger
        plug Corsica, origins: "*"
        plug Plug.Parsers,
            pass: ["*/*"],
            json_decoder: Jason,
            parsers: [:urlencoded, :json, :multipart]
    end
    resources do
        get do
            json(conn, %{hello: :world})
        end

        mount Kiwi.Api.Settings
    end

    rescue_from Unauthorized, as: e do
        Logger.error("#{inspect e}")

        conn
        |> resp({:unauthorized, %{message: e.message}})
    end

    rescue_from [MatchError, RuntimeError], as: e do
        Logger.error("#{inspect e}")

        conn
        |> resp({:error, e})
    end

    rescue_from Maru.Exceptions.NotFound, as: e do
        Logger.error("#{inspect e}")

        conn
        |> resp({:notfound, %{}})
    end

    rescue_from Maru.Exceptions.InvalidFormat, as: e do
        Logger.error("#{inspect e}")

        conn
        |> resp({:badrequest, %{param: e.param, reason: e.reason}})
    end

    rescue_from Maru.Exceptions.Validation, as: e do
        Logger.error("#{inspect e}")

        conn
        |> resp({:badrequest, %{param: e.param, reason: e.validator}})
    end

    rescue_from :all, as: e do
        Logger.error("#{inspect e}")

        conn
        |> resp({:error, e})
    end
end
