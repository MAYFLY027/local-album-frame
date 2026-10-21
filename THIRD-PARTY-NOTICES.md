# Third-party components

This repository contains original launcher/configuration/clock code. It does not contain mpv, FFmpeg, Windows, or CloudDrive binaries, or any photos/videos.

- Playback engine: [mpv](https://mpv.io/), [source](https://github.com/mpv-player/mpv), [licensing](https://github.com/mpv-player/mpv/blob/master/Copyright).
- The installer obtains the x86_64 full build from mpv's first-party [continuous-integration release](https://github.com/mpv-player/mpv/releases/tag/git-release), linked on the official [installation page](https://mpv.io/installation/). CI builds are primarily for testing and may differ from stable releases. Download metadata and SHA256 are recorded under `player/` locally.
- mpv and its included dependencies retain their own licenses. The MIT license in this repository applies only to this project's original files; it does not relicense mpv or its dependencies.
- If distributing a package that includes third-party binaries, review that exact build's licenses, notices and corresponding-source requirements. The source-only repository here intentionally does not redistribute those binaries.
- CloudDrive is an optional external mount provider, not a component authored or distributed by this project. Any readable local Windows folder can be used.
- Windows and Microsoft YaHei UI are system-provided dependencies, not bundled assets.
