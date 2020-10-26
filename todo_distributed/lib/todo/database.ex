defmodule Todo.Database do
  @moduledoc """
  Central singleton process for db management.
  Rather than bothering to hold workers in state, or create supervisor,
  delegate worker management to Poolboy lib.
  """

  @pool_size 3
  @db_folder "./persist"

  @doc """
  This child_spec defers to poolboy child_spec,
  so we no longer need start_link here, since this module is never started
  """
  def child_spec(_) do
    File.mkdir_p!(@db_folder)

    :poolboy.child_spec(
      # Arg 1: Child id
      __MODULE__,
      # Arg 2: Pool options
      [
        name: {:local, __MODULE__},  # register locally to avoid needing pid
        worker_module: Todo.DatabaseWorker,
        size: @pool_size
      ],
      # Arg 3: list of options passed to worker start_link
      [@db_folder]
    )
  end

  @doc """
  Modify store to replicate storage globally, on each node.
  This way, if a node goes down, data will have already been persisted on the others to resume from.
  """
  def store(key, data) do
    {_results, bad_nodes} =
      :rpc.multicall(
        __MODULE__,
        :store_local,
        [key, data],
        :timer.seconds(5)
      )

      Enum.each(bad_nodes, &IO.puts("Store failed on node #{&1}"))
      :ok
  end

  def store_local(key, data) do
    # Poolboy handles "checking out" a worker for this operation
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end
end
