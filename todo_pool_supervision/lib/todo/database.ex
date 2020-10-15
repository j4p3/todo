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
    Enum.map(1..@pool_size, &worker_spec/1) |>
    IO.inspect |> # todo - what's going on here?
    Supervisor.start_link(strategy: :one_for_one)
  end

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
    {Todo.DatabaseWorker, {@db_folder, worker_id}} |>
    Supervisor.child_spec(id: worker_id)
  end
end
