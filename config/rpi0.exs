use Mix.Config

config :logger,
    level: :debug,
    backends: [RingLogger]

config :nerves_time, :servers, [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
]

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"
config :nerves_network, :default,
    wlan0: [
        ssid: System.get_env("NERVES_NETWORK_SSID"),
        psk: System.get_env("NERVES_NETWORK_PSK"),
        key_mgmt: String.to_atom(key_mgmt)
    ]

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
