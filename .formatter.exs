[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test,scripts}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  line_length: 120
]
