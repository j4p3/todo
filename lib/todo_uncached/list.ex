defmodule TodoUncached.List do
  defstruct id_sequence: 1, entries: %{}

  @type todo_list :: %{}
  @type entry :: %{date: Date, message: charlist}

  ###################################################################
  # Interface functions
  ###################################################################

  @spec start :: {atom, pid}
  def start do
    TodoUncached.Server.start(__MODULE__)
  end

  @spec create(pid, any) :: any
  def create(pid, entry) do
    TodoUncached.Server.cast(pid, {:create, entry})
  end

  @spec update(pid, any, any) :: any
  def update(pid, id, entry) do
    TodoUncached.Server.cast(pid, {:update, id, entry})
  end

  @spec delete(pid, any) :: any
  def delete(pid, id) do
    TodoUncached.Server.cast(pid, {:delete, id})
  end

  @spec entries(pid, any) :: [__MODULE__]
  def entries(pid, date) do
    IO.puts("__MODULE__ received entries()")
    TodoUncached.Server.call(pid, {:entries, date})
  end

  ###################################################################
  # Callback functions
  ###################################################################

  def init, do: %__MODULE__{}

  @spec handle_cast(
          {:create, map}
          | {:delete, any}
          | {:update, any, any},
          __MODULE__
        ) :: atom | %{entries: map}
  def handle_cast({:create, entry}, todos) do
    entry = Map.put(entry, :id, todos.id_sequence)

    entries =
      Map.put(
        todos.entries,
        todos.id_sequence,
        entry
      )

    %__MODULE__{
      todos
      | entries: entries,
        id_sequence: todos.id_sequence + 1
    }
  end

  def handle_cast({:update, id, update_body}, todos) do
    case Map.fetch(todos.entries, id) do
      :error ->
        todos

      {:ok, existing_entry} ->
        new_entry =
          Enum.reduce(
            update_body,
            existing_entry,
            fn {k, v}, acc ->
              %{acc | k => v}
            end
          )

        entries =
          Map.put(
            todos.entries,
            new_entry.id,
            new_entry
          )

        %__MODULE__{todos | entries: entries}
    end
  end

  def handle_cast({:delete, id}, todos) do
    {_, updated} = Map.pop(todos.entries, id)
    %__MODULE__{todos | entries: updated}
  end

  def handle_call({:entries, date}, todos) do
    entries =
      todos.entries
      |> Stream.filter(fn {_, entry} -> entry.date == date end)
      |> Enum.map(fn {_, entry} -> entry end)

    {entries, todos}
  end
end
