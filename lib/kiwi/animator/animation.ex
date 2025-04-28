defmodule Kiwi.Animator.Animation do
    require Logger

    def animate(%{} = animation_object, %{} = state) do
        Logger.debug("Animating #{inspect animation_object}")
        new_state = animation_object |> Kiwi.Action.run_action_led(nil, state)
        animate(animation_object, new_state)
    end
end
