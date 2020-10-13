defmodule Todo.Cache do
  use GenServer

  @spec start :: :ignore | {:error, any} | {:ok, pid}
  def start do
    Todo.Database.start()
    GenServer.start(__MODULE__, nil)
  end

  @spec server_process(pid, bitstring) :: any
  def server_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, {:server_process, todo_list_name})
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
end
