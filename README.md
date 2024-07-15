# go2rtc Quick Setup

## Overview

The **go2RTC** package simplifies the installation and management of the go2RTC service on ARM64 systems. go2RTC is a camera streaming application with support RTSP, WebRTC, HomeKit, FFmpeg, RTMP, etc.

### Features

- 🚀 Easy installation with a single command
- 🔄 Option to install or uninstall go2RTC
- ⚙️ Auto-detection mechanism for linux platforms (not implemented)

## Installation

To install go2RTC, execute the following command in your terminal:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/pshedzyal/go2rtc-quick-setup/main/install.sh)"
```

## Usage

Once installed, you can use the following commands:

- To check the service status: `sudo systemctl status go2rtc.service`
- To view recent logs: `journalctl -u go2rtc.service --no-pager | tail -n 50`

## Uninstallation

To uninstall, run the installation script above, just select option #2 (Uninstall).
