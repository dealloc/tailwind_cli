# Tailwind

Mix tasks for installing and invoking the [Tailwind CLI](https://tailwindcss.com/blog/standalone-cli).

Think of it like [esbuild](https://github.com/phoenixframework/esbuild) but for Tailwind.

## Installation

If you are going to build assets in production, then you add
`tailwind` as dependency on all environments but only start it
in dev:

```elixir
def deps do
  [
    {:tailwind, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

However, if your assets are precompiled during development,
then it only needs to be a dev dependency:

```elixir
def deps do
  [
    {:tailwind, "~> 0.1", only: :dev}
  ]
end
```

Now you can install tailwind by running:

```bash
$ mix tailwind.install
```

And invoke tailwind with:

```bash
$ mix tailwind default -i input.css -o output.css
```

The executable is kept at `_build/tailwind-TARGET`.
Where `TARGET` is your system target architecture.

## Profiles

The first argument to `tailwind` is the execution profile.
You can define multiple execution profiles with the current
directory, the OS environment, and default arguments to the
`tailwind` task:

```elixir
config :tailwind,
  default: [
    args: ~w(-i input.css -o output.css),
    cd: Path.expand("../assets", __DIR__)
  ]
```

When `mix tailwind default` is invoked, the task arguments will be appended
to the ones configured above. Note profiles must be configured in your
`config/config.exs`, as `tailwind` runs without starting your application
(and therefore it won't pick settings in `config/runtime.exs`).

## Adding to Phoenix

Installing `tailwind` in a Phoenix application is easy!
Installation requires that Phoenix watchers can accept module-function-args tuples which is not built into Phoenix 1.5.9.

First add it as a dependency in your `mix.exs`:
```elixir
def deps do
  [
    {:tailwind, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

Then modify your `config.exs` file to have tailwind compile `assets/css/app.css` and compile to `priv/static/assets`:
```elixir
config :tailwind,
  default: [
    args: ~w(-i ./css/app.css -o ../priv/static/assets/app.css --content ../lib/*_web/templates/**/*.html.heex),
    cd: Path.expand("../assets", __DIR__)
  ]
```

> Make sure the "assets" directory from priv/static is listed in the
> :only option for Plug.Static in your lib/my_app_web/endpoint.ex

For development, we want to enable watch mode. So find the `watchers`
configuration in your `config/dev.exs` and add:

```elixir
  tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
```

Finally, back in your `mix.exs`, make sure you have a `assets.deploy`
alias for deployments, which will also use the `--minify` option:

```elixir
"assets.deploy": ["tailwind default --minify", "phx.digest"]
```

## License

Copyright (c) 2021 Wannes Gennar.
This project is inspired by, and uses source code of [esbuild](https://github.com/phoenixframework/esbuild), make sure to check them out!
