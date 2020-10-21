defmodule Todo.Database do
  @moduledoc """
  Central singleton process for db management. Spawns three workers, passes DB calls to each.
  Mapping is no longer maintained by a looping server call - instead, creates a registry.
  """

  @pool_size 3
  @db_folder "./persist"

  # Interface
  def start_link() do
    IO.puts("Starting #{__MODULE__}")
    File.mkdir_p!(@db_folder)

    workers = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(workers, strategy: :one_for_one)
  end

  @doc """
  child_spec lets the module specify its own config for being launched by a supervisor,
  rather than defining it in the parent module. (GenServer generates a default :worker spec,
  but the database is no longer keeping state in a server - that's now in the registry.)
  """
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor  # default type is always worker, supervisor type enables supervision tree
    }
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

  defp get_worker(key) do
    :erlang.phash(key, @pool_size) + 1
  end

  defp worker_spec(worker_id) do
    worker_spec = {Todo.DatabaseWorker, {@db_folder, worker_id}}
    Supervisor.child_spec(worker_spec, id: worker_id)  # Why call Supervisor function here rather than worker child_spec method?
  end
end
