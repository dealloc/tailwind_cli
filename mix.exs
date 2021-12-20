defmodule Tailwind.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dealloc/tailwind_cli"

  def project do
    [
      app: :tailwind,
      version: "0.1.0",
      elixir: "~> 1.10",
      deps: deps(),
      description: "Mix tasks for installing and invoking Tailwind CLI",
      package: [
        links: %{
          "Github" => @source_url,
          "Tailwind Cli" => "https://tailwindcss.com/blog/standalone-cli",
          "TailwindCSS" => "https://tailwindcss.com/"
        },
        licenses: ["MIT"]
      ],
      docs: [
        main: "Tailwind",
        source_url: @source_url,
        source_ref: "v#{@version}"
      ],
      xref: [
        exclude: [:httpc, :public_key]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Tailwind, []},
      env: [default: []]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, ">= 0.0.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
