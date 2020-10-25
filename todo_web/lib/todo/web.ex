defmodule Todo.Web do
  use Plug.Router
  plug :match
  plug :dispatch

  def child_spec(_arg) do
    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: [port: Application.get_env(:todo, :http_port, 8888)],
      plug: __MODULE__
    )
  end

  post "/add_entry" do
    IO.puts("POST /add_entry #{__MODULE__}")
    # conn will be in scope after compile from "post" macro
    conn = Plug.Conn.fetch_query_params(conn)

    list_name = Map.fetch!(conn.params, "list")
    entry = %{
      date: Date.from_iso8601!(Map.fetch!(conn.params, "date")),
      title: Map.fetch!(conn.params, "title")
    }

    list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.add_entry(entry)

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(201, "OK")
  end

  get "/entries" do
    IO.puts("GET /entries #{__MODULE__}")
    conn = Plug.Conn.fetch_query_params(conn)

    list_name = Map.fetch!(conn.params, "list")
    date = Date.from_iso8601!(Map.fetch!(conn.params, "date"))

    entries = list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.entries(date)
    |> Enum.map(&("#{&1.date}: #{&1.title}"))
    |> Enum.join("\n")

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, entries)

  end
end
