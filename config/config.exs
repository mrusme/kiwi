use Mix.Config

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :shoehorn,
    init: [:nerves_runtime, :nerves_init_gadget],
    app: Mix.Project.config()[:app]

config :logger,
    level: :debug,
    backends: [RingLogger]
    # backends: [:console]

keys =
    [
        Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
        Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
        Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
    ]
    |> Enum.filter(&File.exists?/1)

if keys == [],
    do:
        Mix.raise("""
        No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
        log into the Nerves device and update firmware on it using ssh.
        See your project's config.exs for this error message.
        """)

config :nerves_firmware_ssh,
    authorized_keys: Enum.map(keys, &File.read!/1)

node_name = if Mix.env() != :prod, do: "kiwi"

config :nerves_init_gadget,
    ifname: "wlan0",
    address_method: :dhcpd,
    mdns_domain: "nerves.local",
    node_name: node_name,
    node_host: :mdns_domain

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"
config :nerves_network, :default,
    wlan0: [
        ssid: System.get_env("NERVES_NETWORK_SSID"),
        psk: System.get_env("NERVES_NETWORK_PSK"),
        key_mgmt: String.to_atom(key_mgmt)
    ]

config :kiwi, Kiwi.Server,
    adapter: Plug.Cowboy,
    plug: Kiwi.Api,
    scheme: :http,
    ip: {0,0,0,0},
    port: 8080

config :kiwi,
    maru_servers: [Paperwork.Server]

config :mnesia, :dir, System.get_env("MNESIA_DUMP_DIRECTORY") || '/root/mnesia_disc_dump'

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
