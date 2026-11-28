<p align="center">
  <img src="desktop/interface/icon.png" width="132" alt="ONYX emblem" />
</p>

<h1 align="center">ONYX // VPN</h1>

<p align="center">Obsidian tones. Brushed silver. Your connection at a glance.</p>

ONYX is a VPN client for Windows and Android that uses Mozilla account sign-in. The Windows dashboard brings connection status, server selection and traffic into one view. Android 1.1.26 uses the native ONYX interface. The Android source also includes the shared dashboard for the next signed update.

## Download ONYX

| Platform | Download | Open |
| --- | --- | --- |
| Windows x64 | **[ONYX for Windows](https://github.com/III85III/ONYX/releases/download/v1.1.33/ONYX-VPN-Setup.exe)** · [Portable ZIP](https://github.com/III85III/ONYX/releases/download/v1.1.33/ONYX-Windows-x64.zip) | Run Setup, then open **ONYX VPN** from your desktop. The dashboard uses Microsoft Edge WebView2 Runtime. |
| Android 8.0+ | **[ONYX for Android](https://github.com/III85III/ONYX/releases/download/v1.1.33/ONYX-VPN.apk)** | Open the downloaded APK on your phone. |

## Connection controls

Choose a server, switch connection modes, and set which apps bypass the VPN on Windows. The dashboard displays connection status and traffic reported by the engine. Some controls in the Windows Shield panel are currently disabled.

Mozilla controls account verification, availability, and quota. ONYX displays the quota reported for your account.

Network ad blocking filters known advertising and tracking domains. YouTube video ads can use the same media hosts as the videos, so this filter does not reliably block in-video ads.

## Source and support

- [Windows client](desktop) · Build with `desktop/Build.ps1` on Windows with .NET Framework 4.8.
- [Android client](mobile/android) · See the [Android build guide](mobile/android/BUILDING.md).
- [Shared Go engine](core) · [GPLv3 license](licenses/GPL-3.0.txt) and [dependency notices](licenses/NOTICE.txt).
- [Release notes](https://github.com/III85III/ONYX/releases) · [Telegram](https://t.me/cabicy)
