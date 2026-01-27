System:
  Kernel: 6.6.87.2-microsoft-standard-WSL2 arch: x86_64 bits: 64 compiler: gcc
    v: 11.2.0
  Console: pty pts/5 Distro: Debian GNU/Linux 13 (trixie)
Machine:
  Message: No machine data: try newer kernel. Is dmidecode installed? Try -M
    --dmidecode.
Battery:
  ID-1: BAT1 charge: 5.0 Wh (100.0%) condition: 5.0/5.0 Wh (100.0%) volts: 5.0
    min: 5.0 model: Microsoft Hyper-V Virtual Battery serial: <filter>
    status: full
CPU:
  Info: 8-core model: AMD Ryzen 7 5800H with Radeon Graphics bits: 64
    type: MT MCP arch: Zen 3 rev: 0 cache: L1: 512 KiB L2: 4 MiB L3: 16 MiB
  Speed (MHz): avg: 3194 min/max: N/A cores: 1: 3194 2: 3194 3: 3194 4: 3194
    5: 3194 6: 3194 7: 3194 8: 3194 9: 3194 10: 3194 11: 3194 12: 3194 13: 3194
    14: 3194 15: 3194 16: 3194 bogomips: 102205
  Flags: avx avx2 ht lm nx pae sse sse2 sse3 sse4_1 sse4_2 sse4a ssse3 svm
Graphics:
  Device-1: Microsoft Basic Render Driver driver: dxgkrnl v: 2.0.3
    bus-ID: 4a3e:00:00.0 chip-ID: 1414:008e
  Device-2: Microsoft Basic Render Driver driver: dxgkrnl v: 2.0.3
    bus-ID: c3b1:00:00.0 chip-ID: 1414:008e
  Display: unspecified server: Microsoft Corporation X.org driver:
    dri: swrast gpu: dxgkrnl,dxgkrnl display-ID: :0 screens: 1
  Screen-1: 0 s-res: 4608x3240 s-dpi: 96
  Monitor-1: XWAYLAND0 pos: primary,top-left res: 3840x2160 hz: 60 size: N/A
  Monitor-2: XWAYLAND1 pos: middle-r res: 768x1366 hz: 60 dpi: 85
    diag: 470mm (18.51")
  Monitor-3: XWAYLAND2 pos: bottom-l res: 1920x1080 hz: 60 dpi: 142
    diag: 394mm (15.53")
  API: EGL v: 1.5 platforms: device: 0 drv: swrast surfaceless: drv: swrast
    x11: drv: swrast inactive: gbm,wayland
  API: OpenGL v: 4.5 vendor: mesa v: 25.0.7-2 glx-v: 1.4 direct-render: yes
    renderer: llvmpipe (LLVM 19.1.7 256 bits) device-ID: ffffffff:ffffffff
  Info: Tools: api: eglinfo,glxinfo x11: xdriinfo, xdpyinfo, xprop, xrandr
Audio:
  Message: No device data found.
Network:
  Message: No PCI device data found.
  IF-ID-1: eth0 state: up speed: 10000 Mbps duplex: full mac: <filter>
Drives:
  Local Storage: total: 1 TiB used: 16.08 GiB (1.6%)
  ID-1: /dev/sda model: Virtual Disk size: 388.4 MiB serial: N/A
  ID-2: /dev/sdb model: Virtual Disk size: 186 MiB serial: N/A
  ID-3: /dev/sdc model: Virtual Disk size: 2 GiB serial: N/A
  ID-4: /dev/sdd model: Virtual Disk size: 1024 GiB serial: N/A
Partition:
  ID-1: / size: 1006.85 GiB used: 16.08 GiB (1.6%) fs: ext4 dev: /dev/sdd
Swap:
  ID-1: swap-1 type: partition size: 2 GiB used: 0 KiB (0.0%) priority: -2
    dev: /dev/sdc
Sensors:
  Src: lm-sensors+/sys Message: No sensor data found using /sys/class/hwmon
    or lm-sensors.
Info:
  Memory: total: 8 GiB note: est. available: 7.43 GiB used: 899.9 MiB (11.8%)
  Processes: 58 Power: uptime: 31m wakeups: 0 Init: systemd v: 257
    default: graphical
  Packages: pm: dpkg pkgs: 1746 Compilers: clang: 19.1.7 gcc: 14.2.0
    Shell: Sudo v: 1.9.16p2 running-in: tmux: inxi: 3.3.38
