defmodule Mix.Tasks.Tailwind do
  @moduledoc """
  Invokes the Tailwind CLI with the given arguments.

  Usage:

      $ mix tailwind PROFILE TAILWIND_CLI_ARGS

  Example:

      $ mix tailwind default -i input.css -o output.css

  If tailwind is not installed, it is automatically downloaded.

  """

  @shortdoc "Invokes tailwind with the profile and args"

  use Mix.Task

  @impl Mix.Task
  def run([profile | args] = all) do
    case Tailwind.install_and_run(String.to_atom(profile), args) do
      0 -> :ok
      status -> Mix.raise("`mix tailwind #{Enum.join(all, " ")}` exited with #{status}")
    end
  end

  def run([]), do: Mix.raise("`mix tailwind` expects the profile as argument")
end
