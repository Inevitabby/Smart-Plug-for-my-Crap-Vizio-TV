# Smart Plug for my Crap Vizio TV

My Vizio TV doesn't support HDMI HPD, so there's no clean way in software to tell whether it's on or off.

I ran through the usual diagnostics first (dmesg, PipeWire, probing it on the network), then escalated to increasingly unhinged ideas, including wiring a Gen 1 Tinkerboard running an extremely optimized DietPi setup into the TV's USB port to act as a power-on beacon[^dietpi]. Eventually I did the sane thing and bought a $12 smart plug.

[^dietpi]: It frequently browned-out or didn't boot fast-enough; the TV's USB port turned out to be extremely spotty

After wasting several hours I just went with the obvious solution and bought a 12 dollar smart plug.

# How It Works

## The Plug

The smart plug is a [KAUF PLF12](https://kaufha.com/plf12), a power monitoring plug that runs ESPHome. The binary sensor `in_use` trips when power draw exceeds a configurable wattage threshold (`sub_threshold`).

A simple firmware tweak was made to make the plug fire a HTTP POST when `in_use` tripped.

## Power Profiling

TV off is 0.393W +/- 0.074W and TV on is 33.500W +/- 12.516W (spiking to 91W when turning on).

Just kidding, TV also sometimes randomly spikes to 10.281W +/- 0.146W after powering off because (???)[^fire]. So `sub_threshold` is 15W.

[^fire]: If I perish in an electrical fire, you may point and laugh at this footnote.

## The Server

`tv-monitor.c` is a minimal HTTP server that listens for the plug's POST requests and calls `kscreen-doctor`.

On startup, it queries the plug's REST API to sync initial monitor state (in case the workstation was started while the TV was already on). If the plug is unreachable at startup, it does nothing and lets the next real event correct state.

I initially tried to make the server be like an all-in-one thing to like start Steam Big Picture or Vacuumtube automatically but it was very complicated and unstable[^wayland] so I decided to split all that stuff into separate .desktop files instead (see: `launch_scripts/`).

[^wayland]: Due to Wayland's security model hating usability, humanity, baby bunnies, and cats.

# Files

- `profiler.sh`: Samples power draw 150 times over 5 minutes and calculates running mean and standard deviation. Requires `profiler_config.sh` (see example).
- `vizio.yaml`: ESPHome firmware config for the plug.
- `tv-monitor.c`: Workstation HTTP server.
	- I start it with KDE autostart so that it inherits the user session environment
- `Makefile`: Builds the C program and compiles the firmware in one shot.

Secrets:

- `config.h.example`: Copy to `config.h` and fill in your workstation IP.
- `secrets.yaml.example`: Copy to `secrets.yaml` and fill in your network details.
- `profiler_config.sh.example`: Copy to `profiler_config.sh` and fill in your plug IP.

# Reuse

This isn't really meant to be reused, a normal person should just set up ESPHome dashboard.

I just did this because installing a whole docker image would've been super overkill for handling a single smart plug.
