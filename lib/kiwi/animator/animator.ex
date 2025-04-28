defmodule Kiwi.Animator do
    require Logger
    use GenServer

    def start_link(args) do
        GenServer.start_link __MODULE__, args, name: __MODULE__
    end

    def init(state) do
        Logger.debug("Init Animator: #{inspect state}")
        {:ok, state}
    end

    def start_task do
        GenServer.cast(__MODULE__, :start_task)
    end

    def stop_task do
        GenServer.cast(__MODULE__, :stop_task)
    end

    def set_state(new_state) do
        GenServer.call(__MODULE__, {:set_state, new_state})
    end

    def handle_call({:set_state, new_state}, _from, state) do
        {:reply, :ok, new_state}
    end

    def handle_call(:start_task, %{task: %Task{ ref: ref}} = state) when is_reference(ref) do
        {:reply, :ok, state}
    end

    def handle_cast(:start_task, %{} = state) do
        Logger.debug("Starting task: #{inspect state}")

        case Kiwi.Collection.Setting.findOne("animation_main") do
            {:ok, found_model} ->
                Logger.debug("Starting animator with animation_main ...")
                animation_object = Kiwi.Helpers.Settings.get_params_from_id_value(found_model) |> Map.get(:object)
                task = Task.Supervisor.async_nolink(Kiwi.Animator.TaskSupervisor, fn -> Kiwi.Animator.Animation.animate(animation_object, state) end)
                Logger.debug("#{inspect task}")

                {:noreply, state |> Map.put(:task, task)}
            other ->
                Logger.debug("Not starting animator because animation_main was not found.")
                {:noreply, state}
        end
    end

    def handle_cast(:stop_task, %{task: task} = state) do
        Logger.debug("Stopping task: #{inspect state}")

        task |> Task.shutdown(2000)

        {:noreply, %{state | task: nil}}
    end

    def handle_cast(:stop_task, %{} = state) do
        Logger.debug("Stopping task not possible, because no task exists: #{inspect state}")
        {:noreply, state |> Map.put(:task, nil)}
    end

    def handle_info({ref, answer}, %{task: %Task{ ref: ref}} = state) when is_reference(ref) do
        Logger.debug("Task completed")
        Process.demonitor(ref, [:flush])
        {:noreply, %{state | task: nil}}
    end

    def handle_info({:DOWN, ref, :process, _pid, _reason}, %{task: %Task{ ref: ref}} = state) do
        Logger.debug("Task failed")
        # TODO: Restart
        {:noreply, %{state | task: nil}}
    end
end
