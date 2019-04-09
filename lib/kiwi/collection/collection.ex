defmodule Kiwi.Collection do
    require Logger
    require Jason
    alias :mnesia, as: Mnesia

    defmacro __using__(_opts) do
        quote do
            defimpl Jason.Encoder, for: [__MODULE__] do
                def encode(value, opts) do
                    value
                    |> Map.delete(:__struct__)
                    |> Jason.Encode.map(opts)
                end
            end

            def keys_to_atoms(string_key_map) when is_map(string_key_map) do
                for {key, val} <- string_key_map, into: %{} do
                    case Enumerable.impl_for val do
                        nil -> {String.to_atom(key), val}
                        _ -> {String.to_atom(key), keys_to_atoms(val)}
                    end
                end
            end
            def keys_to_atoms(value), do: value

            defp get_collection_keys() do
                %__MODULE__{} |> Map.delete(:__struct__) |> Map.keys
            end

            defp init_mnesia_schema() do
                case Mnesia.create_schema([node()]) do
                    :ok -> :ok
                    {:error, {_, {:already_exists, _}}} -> :ok
                    other -> other
                end
            end

            defp init_mnesia_table() do
                case Mnesia.create_table(__MODULE__, [attributes: get_collection_keys(), disc_copies: [Node.self()] ]) do
                    {:atomic, :ok} -> :ok
                    {:aborted, {:already_exists, _}} -> :ok
                    other -> other
                end
            end

            def init() do
                with \
                    :ok <- init_mnesia_schema(),
                    :ok <- Mnesia.start(),
                    :ok <- init_mnesia_table()
                do
                    :ok
                else
                    err -> err
                end
            end

            def tuplify(%__MODULE__{} = model) do
                List.to_tuple([
                    __MODULE__ |
                    model |> Map.delete(:__struct__) |> Map.values
                ])
            end

            def tuplify(%__MODULE__{} = model, true) do
                List.to_tuple([
                    __MODULE__ |
                    (for {k, v} <- Map.delete(model, :__struct__), v != "", do: v)
                ])
            end

            def structify(tuple) do
                map = Enum.zip(get_collection_keys(), Tuple.to_list(tuple))
                |> Enum.into(Map.new, fn
                    # {key, value} when key == :date -> {key, Date.from(value)}
                    {key, value} -> {key, value}
                end)

                struct(__MODULE__, map)
            end

            def upsert(%__MODULE__{} = model) do
                upsert_data = fn -> model |> tuplify |> Mnesia.write end
                case Mnesia.transaction(upsert_data) do
                    {:atomic, :ok} -> :ok
                    other -> other
                end
            end

            def find(%__MODULE__{:id => id} = model) when is_map(model) do
                find_data = fn -> model |> tuplify(true) |> Mnesia.read end
                case Mnesia.transaction(find_data) do
                    {:atomic, data} ->
                        case data |> Enum.map(fn tuple -> tuple |> Tuple.delete_at(0) |> structify end) do
                            [] -> :notfound
                            nil -> :notfound
                            found -> {:ok, found}
                        end
                    _ -> :notfound
                end
            end

            def find(id) when is_binary(id) do
                %__MODULE__{id: id} |> find
            end

            def findOne(%__MODULE__{:id => id} = model) when is_map(model) do
                case model |> find do
                    {:ok, found_models} -> {:ok, found_models |> Enum.at(0)}
                    other -> other
                end
            end

            def findOne(id) when is_binary(id) do
               %__MODULE__{id: id} |> findOne
            end
        end
    end
end

