# Installation

Installer and checksum for [xProject](https://xproject.studio) — a Delphi/Lazarus
compatible web application framework that builds HTML5/JavaScript apps from
Pascal source.

## Install

```sh
curl -fsSL https://xproject.studio/downloads/xProject/install.sh | sh
```

Run it in a terminal. The installer has to read answers from `/dev/tty`, so it
will not work in a non-interactive context.

## Verify the checksum

```sh
curl -fsSL https://xproject.studio/downloads/xProject/install.sh      -o install.sh
curl -fsSL https://raw.githubusercontent.com/xProjectF9/Installation/main/install.sh.sha256 -o install.sh.sha256
sha256sum --check install.sh.sha256
sh install.sh
```

## What the installer does

1. Detects the distribution (Debian/Ubuntu, Fedora/Rocky/AlmaLinux, openSUSE)
   and prints manual installation instructions for anything else.
2. Asks whether the required system libraries should be installed:
   GTK2, OpenSSL, `unzip`, `p7zip` and `wget`. The package names are mapped per
   distribution; `sudo` is used, so you need sudo rights.
3. Asks whether xProject should be downloaded, fetches `xProject.zip` into
   `Lin64/`, extracts it and makes the binary executable.
4. Creates `xProject.sh` in the current directory.
5. Offers to start xProject right away.

Everything is installed into the current working directory, nothing is written
outside of it.


## Supported systems

| System | Notes |
| --- | --- |
| Debian / Ubuntu | `libgtk2.0-0 libssl-dev unzip p7zip-full wget` |
| Fedora / Rocky / AlmaLinux | `gtk2 openssl-devel unzip p7zip wget` |
| openSUSE | `gtk2 libopenssl-devel unzip p7zip wget` |
| Windows | via WSL 2 with a Debian distribution, run the installer inside WSL |

If you skip the dependency step, install those packages yourself — the
downloader needs `wget`, the runtime needs the GTK2 and OpenSSL libraries.

## Manual installation

mkdir -p Lin64
wget -O Lin64/xProject.zip "https://xproject.studio/downloads/xProject/00000000-0000-0000-0000-000000000000/xProject.zip"
unzip Lin64/xProject.zip -d Lin64
rm Lin64/xProject.zip
chmod +x Lin64/xProject


Create `xProject.sh`:

#!/bin/sh

./Lin64/xProject


Make it executable and start it:

chmod +x xProject.sh
./xProject.sh


## Updating

Updates are installed from the Manager, not by running this installer again.

1. Start xProject and press `F1`. The update window opens and shows the
   installed version next to the available remote version for Management,
   Server, Compiler, pas2js, Templates, Units and Demos.
2. Click the **Download** button of the part you want to update. The download
   runs in the background, the button shows the progress and changes to
   `Done` when it is finished.
3. That is all:
   - **Management** updates the Manager itself. A small update script waits
     until the Manager has been closed, extracts the new version (the previous
     one is kept as `xProject.old`) and starts it again.
   - **Server, Compiler, pas2js, Templates, Units, Demos** are unpacked into
     the installation directory.

Your `Config/config.json`, the `Databases/` directory and your projects stay
untouched.


## Files

| File | Purpose |
| --- | --- |
| `install.sh` | The installer, POSIX `sh`, no external dependencies besides curl/wget, unzip and 7z |
| `install.sh.sha256` | SHA256 checksum of `install.sh`, regenerated for every change |

## License

MIT — see [LICENSE](LICENSE).
