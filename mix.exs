defmodule ExApiSpecConverter.MixProject do
  use Mix.Project

  def project do
    [
      name: "ex_api_spec_converter",
      app: :ex_api_spec_converter,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      source_url: "https://github.com/adropofilm/ex_api_spec_converter",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:poison, "~> 5.0"},
      {:httpoison, "~> 1.5", override: true}
    ]
  end

  defp description() do
    "This package helps convert between API specifications. It currently supports Swagger 2 and Postman 2 collections."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/adropofilm/ex_api_spec_converter"}
    ]
  end

end
