use Mix.Config

config :todo, http_port: 8888

import_config "#{Mix.env()}.exs"
