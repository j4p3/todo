defmodule Todo.Server do
  use GenServer

  @spec start(any) :: :ignore | {:error, any} | {:ok, pid}
  def start(name) do
    IO.puts("Starting #{__MODULE__} with name #{name}")
    GenServer.start(__MODULE__, name)
  end

  def create(todo_server, new_entry) do
    GenServer.cast(todo_server, {:create, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  @impl GenServer
  def init(name) do
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
end
