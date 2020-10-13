defmodule Todo.Cache do
  use GenServer

  def start_link(_) do
    IO.puts("Starting #{__MODULE__}")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec server_process(bitstring) :: any
  def server_process(todo_list_name) do
    # Only a single cache, can register name to avoid needing to accept pid
    GenServer.call(__MODULE__, {:server_process, todo_list_name})
  end

  def init(_) do
    Todo.Database.start()
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
