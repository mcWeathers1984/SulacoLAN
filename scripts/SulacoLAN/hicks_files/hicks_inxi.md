System:
  Kernel: 6.1.0-41-amd64 arch: x86_64 bits: 64 compiler: gcc v: 12.2.0 Console: pty pts/0
    Distro: Debian GNU/Linux 12 (bookworm)
Machine:
  Type: Desktop System: HP product: HP Slim Desktop 290-p0xxx v: N/A serial: <filter> Chassis:
    type: 3 serial: <filter>
  Mobo: HP model: 843F v: 00 serial: <filter> UEFI: AMI v: F.48 date: 07/27/2022
CPU:
  Info: dual core model: Intel Celeron G4900 bits: 64 type: MCP arch: Coffee Lake rev: B cache:
    L1: 128 KiB L2: 512 KiB L3: 2 MiB
  Speed (MHz): avg: 800 min/max: 800/3100 cores: 1: 800 2: 800 bogomips: 12399
  Flags: ht lm nx pae sse sse2 sse3 sse4_1 sse4_2 ssse3 vmx
Graphics:
  Device-1: Intel CoffeeLake-S GT1 [UHD Graphics 610] vendor: Hewlett-Packard driver: i915
    v: kernel arch: Gen-9.5 ports: active: HDMI-A-1 empty: DP-1 bus-ID: 00:02.0 chip-ID: 8086:3e93
  Display: server: X.org v: 1.21.1.7 compositor: xfwm driver: X: loaded: modesetting
    unloaded: fbdev,vesa dri: iris gpu: i915 tty: 122x69
  Monitor-1: HDMI-A-1 model: Asus VW246 res: 1920x1080 dpi: 92 diag: 609mm (24")
  API: OpenGL Message: GL data unavailable in console for root.
Audio:
  Device-1: Intel Cannon Lake PCH cAVS vendor: Hewlett-Packard driver: snd_hda_intel v: kernel
    bus-ID: 00:1f.3 chip-ID: 8086:a348
  API: ALSA v: k6.1.0-41-amd64 status: kernel-api
  Server-1: PulseAudio v: 16.1 status: active (root, process)
Network:
  Device-1: Realtek RTL8111/8168/8411 PCI Express Gigabit Ethernet
    vendor: Hewlett-Packard RTL8111/8168/8211/8411 driver: r8169 v: kernel pcie: speed: 2.5 GT/s
    lanes: 1 port: 4000 bus-ID: 01:00.0 chip-ID: 10ec:8168
  IF: enp1s0 state: up speed: 1000 Mbps duplex: full mac: <filter>
  Device-2: Realtek RTL8821CE 802.11ac PCIe Wireless Network Adapter vendor: Hewlett-Packard
    driver: rtw_8821ce v: N/A pcie: speed: 2.5 GT/s lanes: 1 port: 3000 bus-ID: 02:00.0
    chip-ID: 10ec:c821
  IF: wlp2s0 state: down mac: <filter>
  IF-ID-1: docker0 state: down mac: <filter>
Bluetooth:
  Device-1: Realtek Bluetooth 4.2 Adapter type: USB driver: btusb v: 0.8 bus-ID: 1-14:2
    chip-ID: 0bda:b00a
  Report: rfkill ID: hci0 rfk-id: 0 state: down bt-service: not found rfk-block: hardware: no
    software: no address: see --recommends
Drives:
  Local Storage: total: 465.76 GiB used: 10.4 GiB (2.2%)
  ID-1: /dev/sda vendor: Toshiba model: DT01ACA050 size: 465.76 GiB speed: 6.0 Gb/s
    serial: <filter>
Partition:
  ID-1: / size: 455.95 GiB used: 10.4 GiB (2.3%) fs: ext4 dev: /dev/sda2
  ID-2: /boot/efi size: 511 MiB used: 5.8 MiB (1.1%) fs: vfat dev: /dev/sda1
Swap:
  ID-1: swap-1 type: partition size: 976 MiB used: 0 KiB (0.0%) priority: -2 dev: /dev/sda3
Sensors:
  System Temperatures: cpu: 42.0 C pch: 50.0 C mobo: N/A
  Fan Speeds (RPM): N/A
Info:
  Processes: 180 Uptime: 2d 2h 44m Memory: 31.18 GiB used: 2.06 GiB (6.6%) Init: systemd v: 252
  target: multi-user (3) default: multi-user Compilers: gcc: 12.2.0 alt: 12 clang: 14.0.6
  Packages: pm: dpkg pkgs: 2012 Shell: Bash v: 5.2.15 running-in: pty pts/0 inxi: 3.3.26
