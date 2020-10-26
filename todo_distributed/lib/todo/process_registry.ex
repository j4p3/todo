defmodule Todo.ProcessRegistry do
  def start_link do
    IO.puts("Starting #{__MODULE__}")
    Registry.start_link(name: __MODULE__, keys: :unique)
  end

  @doc """
  Generate a via tuple to register a process with this registry
  """
  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
