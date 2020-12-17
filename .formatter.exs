[
  import_deps: [:ecto, :phoenix, :ecto_sql, :grpc],
  inputs: [
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"],
  line_length: 120
]
