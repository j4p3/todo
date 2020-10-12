defmodule TodoCache.Server do
  @spec start(atom) :: pid
  def start(callback_module) do
    {:ok,
     spawn(fn ->
       initial_state = callback_module.init()
       loop(callback_module, initial_state)
     end)}
  end

  @spec call(pid, any) :: any
  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} -> response
    end
  end

  @spec cast(pid, any) :: any
  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, current_state)
        loop(callback_module, new_state)
    end
  end
end
