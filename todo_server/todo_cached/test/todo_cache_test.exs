defmodule TodoCacheTest do
  use ExUnit.Case

  test "server process" do
    {:ok, cache} = Todo.Cache.start()
    a_pid = Todo.Cache.server_process(cache, "a")

    assert a_pid != Todo.Cache.server_process(cache, "b")
    assert a_pid == Todo.Cache.server_process(cache, "a")
  end

  test "todos" do
    {:ok, cache} = Todo.Cache.start()
    a_pid = Todo.Cache.server_process(cache, "a")

    date = ~D[2020-10-12]
    entry = %{date: date, message: "do the thing"}
    Todo.List.create(a_pid, entry)
    entries = Todo.List.entries(a_pid, date)

    assert entries = [entry]
  end
end
