# Smart Plug for my Crap Vizio TV

We all know what happens when you give a mouse a cookie, but what about when you give me a crappy TV that doesn't support HDMI HPD and whose on/off state is totally invisible to your computer?

The answer, dear reader, is simple.

You get a smart plug, compile firmware that makes it send a HTTP POST to my computer when the power draw crosses 15W, and write a C program for my PC that consumes the notifications and calls `kscreen-doctor output.HDMI-A-4.enable` and `kscreen-doctor output.HDMI-A-4.disable` so KDE can enable and disable the monitor.

All of this, to avoid having to press `Meta+P` and clicking a button to manually enable and disable the monitor.

# How It Works

## The Plug

The smart plug is a [KAUF PLF12](https://kaufha.com/plf12), a power monitoring plug that runs ESPHome. The firmware is configured to watch a binary sensor (`in_use`) that trips when power draw exceeds a configurable wattage threshold (`sub_threshold`). When the sensor trips or clears, the plug fires a HTTP POST to the workstation.

`vizio.yaml` is built on top of KaufHA's official package, so it retains all the stock KAUF functionality (web UI, Home Assistant integration, LED config, etc.) while adding the HTTP request behavior on top via `!extend`.

## Power Profiling

TV off is 0.393W +/- 0.074W and TV on is 33.500W +/- 12.516W (spiking to 91W when turning on). You'd think 3W would be a fine threshold, and it was, until I discovered the TV randomly spikes to 10.281W +/- 0.146W after powering off because God hates me. So `sub_threshold` is 15W.

`profiler.sh` samples the plug's power sensor 150 times over 5 minutes and prints a running mean and standard deviation. I used it to figure out the above numbers.

## The Server

`tv-monitor.c` is a minimal HTTP server that listens for the plug's POST requests and calls `kscreen-doctor` via `fork()`/`execvp()`. I start it with KDE autostart so that it inherits the user session environment, which is necessary for `kscreen-doctor` to actually see the display.

On startup, it queries the plug's REST API to sync initial monitor state in case the workstation was started while the TV was already on. If the plug is unreachable at startup, it does nothing and lets the next real event correct state. Graceful degradation, very professional, I am a very serious engineer.

The reason I'm not using Python is because it feels icky to spend 20MB of RAM 24/7/365 to handle an event that only happens a few times a week. I am very technologically hygieneful. Don't look at the ten billion random Bash scripts in my KDE autostart.

# Files

- `profiler.sh`: Samples power draw 150 times over 5 minutes, calculates mean and standard deviation. Requires `profiler_config.sh` (see example).
- `vizio.yaml`: ESPHome firmware config for the plug.
- `tv-monitor.c`: Workstation HTTP server.
- `Makefile`: Builds the C program and compiles the firmware in one shot.

Secrets:

- `config.h.example`: Copy to `config.h` and fill in your workstation IP. Gitignored.
- `secrets.yaml.example`: Copy to `secrets.yaml` and fill in your network details. Gitignored.
- `profiler_config.sh.example`: Copy to `profiler_config.sh` and fill in your plug IP. Gitignored.

# Reuse

This isn't really meant to be reused, a normal person should just set up ESPHome dashboard.

I just did this because installing a whole docker image would've been super overkill for handling a single smart plug.
