defmodule Todo.Server do
  @moduledoc """
  Uses agent rather than genserver.
  Tidies things up a bit - no need for interface function to cast,
  Then implementation function to handle cast.
  Just pass the impl to the agent right from the interface function.
  """
  use Agent, restart: :temporary

  @doc """
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name) do
    Agent.start_link(
      fn ->
        IO.puts("Starting #{__MODULE__} with name #{name}")
        {name, Todo.Database.get(name) || Todo.List.new()}
      end
    )
  end

  def create(todo_server, new_entry) do
    Agent.cast(
      todo_server, fn {name, todo_list} ->
        new_state = Todo.List.create(todo_list, new_entry)
        Todo.Database.store(name, new_state)
        {name, new_state}
      end
    )
  end

  def entries(todo_server, date) do
    Agent.get(
      todo_server, fn date ->
        Todo.List.entries(todo_list, date)
      end
    )
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
