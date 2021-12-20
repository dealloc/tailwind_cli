defmodule Tailwind do
  # see https://github.com/tailwindlabs/tailwindcss/releases
  @latest_version "3.0.7"

  @moduledoc """
  Tailwind is an installer and runner for [Tailwind CLI](https://tailwindcss.com/blog/standalone-cli).

  Think [esbuild](https://github.com/phoenixframework/esbuild) but for Tailwind,
  allowing you to scratch NodeJS from your toolchain entirely.

  ## Profiles

  You can define multiple `tailwind` profiles,
  each profile configures arguments, current directory and environment variables:

      config :tailwind,
        # Version is optional, latest version will automatically be used if not specified.
        version: "#{@latest_version}",
        default: [
          args: ~w(-i input.css -o output.css),
          cd: Path.expand("../assets", __DIR__),
          env: %{"SOME_VAR" => "some value"}
        ]

  ## Tailwind configuration
  There are two global configurations for the tailwind application:
    * `:version` - the expected tailwind cli version
    * `:path` - the path to find the tailwind cli executable at. By
      default, it is automatically downloaded and placed inside
      the `_build` directory of your current app

  Overriding the `:path` is not recommended, as we will automatically
  download and manage `tailwind` for you. But in case you can't download
  it (for example, you're behind a proxy), you may want to
  set the `:path` to a configurable system location.
  """

  use Application
  require Logger

  @doc false
  def start(_, _) do
    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Gets the latest version available for Tailwind CLI at the moment of publishing.
  """
  def latest_version, do: @latest_version

  @doc """
  Installs, if not available, and then runs `tailwind`.
  Returns the same as `run/2`.
  """
  def install_and_run(profile, args) do
    install()

    run(profile, args)
  end

  @doc """
  Runs the given command with `args`.
  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  def run(profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = config_for!(profile)
    args = config[:args] || []

    opts = [
      cd: config[:cd] || File.cwd!(),
      env: config[:env] || %{},
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    bin_path()
    |> System.cmd(args ++ extra_args, opts)
    |> elem(1)
  end

  @doc """
  Installs `tailwind` in your system,
  if `:force` is passed the install is always done regardless if the binary already exists.
  """
  def install(:force) do
    bin_path = bin_path()

    if File.exists?(bin_path) do
      File.rm!(bin_path)
    end

    Logger.info("Reinstalling Tailwind CLI v#{configured_version()}")
    install()
  end

  def install() do
    version = configured_version()
    bin_path = bin_path()

    unless File.exists?(bin_path) do
      url =
        "https://github.com/tailwindlabs/tailwindcss/releases/download/v#{version}/tailwindcss-#{target()}"

      binary = fetch_body!(url)

      File.mkdir_p!(Path.dirname(bin_path))
      File.write!(bin_path, binary, [:binary])
      File.chmod(bin_path, 0o755)
    end
  end

  # Get the configured version, defaults to the latest available version.
  defp configured_version, do: Application.get_env(:tailwind, :version, latest_version())

  # Gets the platform target (linux-64, macos-arm64, windows-x64.exe)
  defp target do
    case :os.type() do
      {:win32, _} ->
        "windows-#{:erlang.system_info(:wordsize) * 8}.exe"

      {:unix, osname} ->
        arch_str = :erlang.system_info(:system_architecture)
        [arch | _] = arch_str |> List.to_string() |> String.split("-")
        osname = case osname do
          :darwin ->
            :macos
          osname ->
            osname
        end

        case arch do
          "amd64" -> "#{osname}-x64"
          "x86_64" -> "#{osname}-x64"
          "aarch64" when osname == :macos -> "#{osname}-arm64"
          "arm" when osname == :macos -> "#{osname}-arm64"
          _ -> raise "esbuild is not available for architecture: #{arch_str}"
        end
    end
  end

  # copied from https://github.com/phoenixframework/esbuild/blob/main/lib/esbuild.ex
  defp fetch_body!(url) do
    url = String.to_charlist(url)
    Logger.debug("Downloading Tailwind CLI from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy") do
      Logger.debug("Using HTTP_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:proxy, {{String.to_charlist(host), port}, []}}])
    end

    if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      Logger.debug("Using HTTPS_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = CAStore.file_path() |> String.to_charlist()

    http_options = [
      ssl: [
        verify: :verify_peer,
        cacertfile: cacertfile,
        depth: 2,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise "couldn't fetch #{url}: #{inspect(other)}"
    end
  end

  @doc """
  Returns the path to the executable.
  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    name = "tailwind-#{target()}"

    Application.get_env(:tailwind, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), name)
      else
        Path.expand("_build/#{name}")
      end
  end

  @doc """
  Returns the configuration for the given profile.
  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
    Application.get_env(:tailwind, profile) ||
      raise ArgumentError, """
      unknown Tailwind profile. Make sure the profile is defined in your config/config.exs file, such as:
          config :tailwind,
            #{profile}: [
              args: ~w(build -i ./css/app.css -o=../priv/static/assets/app.css),
              cd: Path.expand("../assets", __DIR__)
            ]
      """
  end
end
