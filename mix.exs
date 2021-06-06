defmodule Kiwi.MixProject do
    use Mix.Project

    @app :kiwi
    @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :bbb, :x86_64]

    def project do
        [
            app: @app,
            version: "1.0.1",
            elixir: "~> 1.9",
            archives: [nerves_bootstrap: "~> 1.10"],
            start_permanent: Mix.env() == :prod,
            build_embedded: true,
            preferred_cli_target: [run: :host, test: :host],
            aliases: [loadconfig: [&bootstrap/1]],
            releases: [{@app, release()}],
            deps: deps()
        ]
    end

    def bootstrap(args) do
        Application.start(:nerves_bootstrap)
        Mix.Task.run("loadconfig", args)
    end

    def application do
        [
            mod: {Kiwi.Application, []},
            extra_applications: [:logger, :runtime_tools, :mnesia],
            # included_applications: [:mnesia]
        ]
    end

    def release do
        [
            overwrite: true,
            cookie: "#{@app}_cookie",
            include_erts: &Nerves.Release.erts/0,
            steps: [&Nerves.Release.init/1, :assemble],
            strip_beams: Mix.env() == :prod
        ]
    end
    defp deps do
        [
            # Dependencies for all targets
            {:nerves, "~> 1.7", runtime: false},
            {:shoehorn, "~> 0.6"},
            {:ring_logger, "~> 0.6"},
            {:toolshed, "~> 0.2"},
            {:circuits_gpio, "~> 0.4"},
            {:circuits_spi, "~> 0.1"},
            {:circuits_i2c, "~> 0.3"},
            {:maru, "~> 0.14.0-pre.1"},
            {:plug_cowboy, "~> 2.0"},
            {:jason, "~> 1.1"},
            {:corsica, "~> 1.1"},
            {:mojito, "~> 0.2"},
            {:nerves_time, "~> 0.2", targets: @all_targets},

            # Dependencies for all targets except :host
            {:nerves_runtime, "~> 0.6", targets: @all_targets},
            {:nerves_init_gadget, "~> 0.4", targets: @all_targets},

            # Dependencies for specific targets
            {:nerves_system_rpi, "~> 1.8", runtime: false, targets: :rpi},
            {:nerves_system_rpi0, "~> 1.8", runtime: false, targets: :rpi0},
            {:nerves_system_rpi2, "~> 1.8", runtime: false, targets: :rpi2},
            {:nerves_system_rpi3, "~> 1.8", runtime: false, targets: :rpi3},
            {:nerves_system_rpi3a, "~> 1.8", runtime: false, targets: :rpi3a},
            {:nerves_system_x86_64, "~> 1.8", runtime: false, targets: :x86_64},
            {:nerves_system_bbb, "~> 2.3", runtime: false, targets: :bbb},
        ]
    end
end
