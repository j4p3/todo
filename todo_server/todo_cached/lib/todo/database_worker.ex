defmodule Todo.DatabaseWorker do
  @moduledoc """
  Performs DB reads & writes, returns status to caller (central DB module).
  """

  # interface
  # nice to have interface functions here, even though the database could just pass messages directly.
  # * prevents clients from needing details on implementation
  # * allows us to encapsulate all worker process message passing internally
  def start(db_folder) do
    IO.puts("Starting #{__MODULE__}")
    GenServer.start(__MODULE__, db_folder)
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  # callback
  def init(db_folder) do
    {:ok, db_folder}
  end

  def handle_cast({:store, key, data}, db_folder) do
    file_name(db_folder, key)
    |> File.write!(:erlang.term_to_binary(data))
  end

  def handle_call({:get, key}, _, db_folder) do
    data =
      case File.read(file_name(db_folder, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, db_folder}
  end

  defp file_name(path, key) do
    Path.join(path, to_string(key))
  end
end
