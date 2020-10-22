defmodule Todo.Server do
  @moduledoc """

  """
  use GenServer, restart: :temporary
  @idle_timeout :timer.seconds(30)

  @doc """

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
    {:ok, {name, Todo.Database.get(name) || Todo.List.new()}, @idle_timeout}
  end

  @impl GenServer
  def handle_cast({:create, new_entry}, {name, todo_list}) do
    new_state = Todo.List.create(todo_list, new_entry)
    Todo.Database.store(name, new_state)
    {:noreply, {name, new_state}, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list},
      @idle_timeout
    }
  end

  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    IO.puts("Stopping #{__MODULE__} with name #{name}")
    {:stop, :normal, {name, todo_list}}
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
