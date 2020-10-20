defmodule Todo.Server do
  @moduledoc """
  Not restarted with :temporary strategy
  Useful to not hit the supervisor's restart threshold
  Todo servers would be restarted on the next cache request anyway
  """
  use GenServer, restart: :temporary

  @doc """
  This is where the server de-duping is actually happening.
  When a request comes in to cache, it attempts to start a server for the given name.
  GenServer.start_link returns an error code, since it's a duplicate, and we handle that in cache.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name) do
    GenServer.start_link(Todo.Server, name, name: via_tuple(name))
  end

  def create(todo_server, new_entry) do
    GenServer.cast(todo_server, {:create, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  @impl GenServer
  def init(name) do
    IO.puts("Starting #{__MODULE__} with name #{name}")
    {:ok, {name, Todo.Database.get(name) || Todo.List.new()}}
  end

  @impl GenServer
  def handle_cast({:create, new_entry}, {name, todo_list}) do
    new_state = Todo.List.create(todo_list, new_entry)
    Todo.Database.store(name, new_state)
    {:noreply, {name, new_state}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list}
    }
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
