defmodule Kiwi.Collection do
    require Logger
    require Jason
    alias :mnesia, as: Mnesia

    def init_mnesia_directory() do
        case File.exists?(Mnesia.system_info(:directory)) do
            true -> :ok
            false ->
                with \
                    :stopped <- Mnesia.stop(),
                    :ok <- Logger.debug("Mnesiahack: Mnesia stopped."),
                    :ok <- :timer.sleep(:timer.seconds(1)),
                    :ok <- Mnesia.delete_schema([node()]),
                    :ok <- Logger.debug("Mnesiahack: Schema deleted."),
                    :ok <- :timer.sleep(:timer.seconds(1)),
                    :ok <- File.mkdir(Mnesia.system_info(:directory))
                do
                    :ok
                else
                    other -> {:error, other}
                end
        end
    end

    def init_mnesia_schema() do
        case Mnesia.create_schema([node()]) do
            :ok -> :ok
            {:error, {_, {:already_exists, _}}} -> :ok
            other -> other
        end
    end

    # This Mnesia bullshit has cost me two nights of my life and roughly $23 for coffee that I ain't going to
    # get back. At least let me enjoy ranting and making fun of Mnesia's stupid face. Such a stupid face.
    def init_collection() do
        with \
            :ok <- init_mnesia_directory(),
            :ok <- Logger.debug("Mnesiahack: Directory created."),
            :ok <- :timer.sleep(:timer.seconds(1)),
            :stopped <- Mnesia.stop(),
            :ok <- Logger.debug("Mnesiahack: Mnesia stopped, maybe again, whatever."),
            :ok <- :timer.sleep(:timer.seconds(1)),
            :ok <- init_mnesia_schema(),
            :ok <- Logger.debug("Mnesiahack: Schema initialized, at least if it wasn't there before."),
            :ok <- :timer.sleep(:timer.seconds(1)),
            :ok <- Mnesia.start(),
            :ok <- Logger.debug("Mnesiahack: Mnesia started."),
            :ok <- :timer.sleep(:timer.seconds(1))
        do
            Logger.debug("Mnesiahack: All done.")
            :ok
        else
            err ->
                Logger.error "Mnesia has failed, again!"
                Logger.debug "#{inspect err}"
                err
        end
    end

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

            def get_collection_keys() do
                [:id | %__MODULE__{} |> Map.delete(:__struct__) |> Map.delete(:id) |> Map.keys |> Enum.sort]
            end

            def init_mnesia_table(opts) do
                case Mnesia.create_table(__MODULE__, opts) do
                    {:atomic, :ok} -> :ok
                    {:aborted, {:already_exists, _}} -> :ok
                    other -> other
                end
            end

            def tuplify(%__MODULE__{} = model) do
                List.to_tuple([
                    __MODULE__ | [
                        model |> Map.get(:id) |
                        model |> Map.delete(:__struct__) |> Map.delete(:id) |> Enum.to_list |> Enum.sort(fn({key1, value1}, {key2, value2}) -> key1 < key2 end) |> Enum.into(%{}) |> Map.values
                    ]
                ])
            end

            def tuplify(%__MODULE__{} = model, true) do
                List.to_tuple([
                    __MODULE__,
                    model |> Map.get(:id)
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

            def all() do
                all_data = fn -> Mnesia.foldl(fn(a, b) -> [a|b] end, [], __MODULE__) end
                case Mnesia.transaction(all_data) do
                    {:atomic, data} ->
                        case data |> Enum.map(fn tuple -> tuple |> Tuple.delete_at(0) |> structify end) do
                            [] -> :notfound
                            nil -> :notfound
                            all -> {:ok, all}
                        end
                    _ -> :notfound
                end
            end
        end
    end
end

