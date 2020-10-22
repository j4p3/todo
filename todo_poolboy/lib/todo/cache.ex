defmodule Todo.Cache do
  def start_link() do
    IO.puts("Starting #{__MODULE__}")
    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  @doc """
  No need to maintain state in a server process and call it -
  Instead, state is in supervisor, child lookup there
  """
  @spec server_process(bitstring) :: any
  def server_process(todo_list_name) do
    case start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def init(_) do
    {:ok, %{}}
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  defp start_child(name) do
    # Pass the work to DynamicSupervisor
    # These calls are serialized, so multiple calls for the same list will get the same server
    # However, since they're serialized, this is a bottleneck
    DynamicSupervisor.start_child(
      __MODULE__,
      {Todo.Server, name}
    )
  end
end
