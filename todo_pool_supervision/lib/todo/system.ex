defmodule Todo.System do
  @spec start_link :: {:error, any} | {:ok, pid}
  def start_link do
    Supervisor.start_link(
      [
        Todo.ProcessRegistry,
        Todo.Cache,
        Todo.Database
      ],
      strategy: :one_for_one
    )
  end
end

defmodule Todo.CallbackSystem do
  @moduledoc """
  A more complex way to start a system, giving more access to post-system-start,
  pre-module-init hooks. Also nice for module code reloading without restarting system.
  """
  use Supervisor

  @spec start_link :: {:error, any} | {:ok, pid}
  @doc """
  Interface function telling supervisor to run this module's init method
  """
  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  @doc """
  Callback function, called by supervisor, to perform whatever init actions
  and start system.
  """
  def init(_) do
    Supervisor.init([Todo.Cache],
      strategy: :one_for_one
    )
  end
end
