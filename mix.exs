defmodule ExMagery.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_magery,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod
      description: description(),
      package: package(),,
      deps: deps(),
      name: "ExMagery",
      source_url: "https://github.com/mattschlobohm/ex_magery/"
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
      {:apex, "~> 1.1.0"},
      {:floki, "~> 0.19.0"},
      {:poison, "~> 3.1.0"}
    ]
  end


  defp description() do
    "Backend for a Magery HTML template system"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "postgrex",
      # These are the default files included in the package
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Matt Schlobohm"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mattschlobohm/ex_magery/"}
    ]
  end
end
