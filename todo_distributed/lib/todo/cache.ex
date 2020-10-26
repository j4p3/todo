defmodule Todo.Cache do
  def start_link() do
    IO.puts("Starting #{__MODULE__}")
    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  @doc """
  Eliminate bottleneck - made more serious now that it's a global lock to try to register -
  by performing a lookup first
  """
  @spec server_process(bitstring) :: any
  def server_process(todo_list_name) do
    existing_process(todo_list_name) || new_process(todo_list_name)
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

  defp existing_process(name) do
    Todo.Server.whereis(name)
  end

  defp new_process(name) do
    case DynamicSupervisor.start_child(
      __MODULE__,
      {Todo.Server, name}
    ) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
