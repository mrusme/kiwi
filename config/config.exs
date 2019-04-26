use Mix.Config

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :shoehorn,
    init: [:nerves_runtime, :nerves_init_gadget],
    app: Mix.Project.config()[:app]

node_name = if Mix.env() != :prod, do: "kiwi"

config :nerves_init_gadget,
    ifname: "wlan0",
    address_method: :dhcpd,
    mdns_domain: "nerves.local",
    node_name: node_name,
    node_host: :mdns_domain

config :kiwi, Kiwi.Server,
    adapter: Plug.Cowboy,
    plug: Kiwi.Api,
    scheme: :http,
    ip: {0,0,0,0},
    port: 8080

config :kiwi,
    maru_servers: [Paperwork.Server]

config :mnesia,
    dir: String.to_charlist(System.get_env("MNESIA_DUMP_DIRECTORY") || "/root/mnesia_disc_dump"),
    debug: :debug,
    # dump_disc_copies_at_startup: true
    schema_location: :opt_disc

import_config "#{Mix.target()}.exs"
