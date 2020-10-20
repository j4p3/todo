defmodule Todo.Cache do
  use GenServer

  def start_link(_) do
    IO.puts("Starting #{__MODULE__}")
    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  @spec server_process(bitstring) :: any
  def server_process(todo_list_name) do
    # Only a single cache, can register name to avoid needing to accept pid
    GenServer.call(__MODULE__, {:server_process, todo_list_name})
    case start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def init(_) do
    {:ok, %{}}
  end

  # handle_call takes request, caller, state
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        # get or create
        {:ok, new_server} = Todo.Server.start(todo_list_name)
        {:reply, new_server, Map.put(todo_servers, todo_list_name, new_server)}
    end
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  defp start_child(name) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Todo.Server, name}
    )
  end
end
