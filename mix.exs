defmodule RealDebrid.MixProject do
  use Mix.Project

  def project do
    [
      app: :real_debrid_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for the Real-Debrid API",
      package: package(),
      source_url: "https://github.com/sushydev/real_debrid_ex"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/sushydev/real_debrid_ex"},
      files: ~w(lib mix.exs README.md)
    ]
  end
end
