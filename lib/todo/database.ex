defmodule Todo.Database do
  @moduledoc """
  Central singleton process for db management. Spawns three workers, maintains mapping, passes DB calls to each.
  """
  use GenServer

  @db_folder "./persist"

  # Interface
  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    key |>
    get_worker() |>
    Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key |>
    get_worker() |>
    Todo.DatabaseWorker.get(key)
  end

  # Callback

  def init(_) do
    File.mkdir_p!(@db_folder)
    {:ok, create_workers()}
  end

  def handle_call({:get_worker, key}, _, workers) do
    {:reply, Map.get(workers, :erlang.phash(key, 3)), workers}
  end

  defp get_worker(key) do
    GenServer.call(__MODULE__, {:get_worker, key})
  end

  defp create_workers() do
    for i <- 0..2, into: %{} do
      {:ok, pid} = Todo.DatabaseWorker.start(@db_folder)
      {i, pid}
    end
  end
end
