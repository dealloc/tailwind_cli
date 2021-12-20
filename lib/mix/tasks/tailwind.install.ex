defmodule Mix.Tasks.Tailwind.Install do
  @moduledoc """
  Installs Tailwind CLI (by default under `_build`).

  ```bash
  $ mix tailwind.install
  $ mix tailwind.install --force
  ```

  By default, it installs #{Tailwind.latest_version()} but you
  can configure it in your config files, such as:
      config :tailwind, :version, "#{Tailwind.latest_version()}"
  ## Options

      * `--force` - Always installs, even if the binary already exists.
  """

  @shortdoc "Installs Tailwind under _build"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    options = [force: :boolean]

    case OptionParser.parse_head!(args, strict: options) do
      {opts, []} ->
        if opts[:force] do
          Tailwind.install(:force)
        else
          Tailwind.install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to tailwind.install, expected one of:
            mix tailwind.install
            mix tailwind.install --force
        """)
    end
  end
end
