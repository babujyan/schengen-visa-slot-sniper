# Schengen Visa Slot Sniper

[![CI](https://github.com/smol-ninja/schengen-visa-slot-sniper/actions/workflows/ci.yml/badge.svg)](https://github.com/smol-ninja/schengen-visa-slot-sniper/actions/workflows/ci.yml)

<img src="resources/favicon.png" alt="Schengen Visa Slot Sniper" width="128" />

Chrome extension that automatically finds and books Schengen visa appointments on TLSContact.

- Automatic appointment scanning with configurable refresh intervals
- Auto-booking when slots are found
- Reschedule mode — keeps scanning for better slots after booking
- Date, time, and day-of-week filtering
- Telegram notifications when appointments are found or booked
- Support for Germany, France, Belgium, Italy, and Netherlands

## Install

1. Clone and build:

```shell
git clone https://github.com/smol-ninja/schengen-visa-slot-sniper.git && cd schengen-visa-slot-sniper
bun install
just build
```

2. Open `chrome://extensions/`, enable **Developer Mode**, click **Load unpacked**, and select the project directory.

## Usage

1. Open the extension popup and enter your TLSContact credentials.
2. Select your destination country and click **Test Details**.
3. Configure refresh rate and filtering options.
4. Click **Start Scanning**.

The extension scans at your configured interval. When a matching slot is found, it books automatically and sends a
desktop notification.

### Telegram Notifications

1. Create a bot via [@BotFather](https://t.me/BotFather) and copy the bot token.
2. Get your Chat ID via [@userinfobot](https://t.me/userinfobot).
3. Enable Telegram in the extension settings and enter both values.

### Reschedule Mode

When enabled, the extension continues scanning after a successful booking. If a better slot is found, it cancels the
existing appointment and books the new one.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

[GPL-3.0](./LICENSE)
