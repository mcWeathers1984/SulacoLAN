Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Users\mikew> Get-ComputerInfo | Select-Object `
>>   CsName, OsName, OsVersion, OsBuildNumber, OsArchitecture, WindowsVersion, `
>>   CsManufacturer, CsModel, BiosManufacturer, BiosSMBIOSBIOSVersion, BiosReleaseDate


CsName                : RIPLEY
OsName                : Microsoft Windows 11 Home
OsVersion             : 10.0.26200
OsBuildNumber         : 26200
OsArchitecture        : 64-bit
WindowsVersion        : 2009
CsManufacturer        : HP
CsModel               : Victus by HP Gaming Laptop 15-fb0xxx
BiosManufacturer      : AMI
BiosSMBIOSBIOSVersion : F.22
BiosReleaseDate       : 7/22/2024 6:00:00 PM



PS C:\Users\mikew> Get-CimInstance Win32_Processor | Select-Object `
>>   Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, `
>>   L2CacheSize, L3CacheSize


Name                      : AMD Ryzen 7 5800H with Radeon Graphics
Manufacturer              : AuthenticAMD
NumberOfCores             : 8
NumberOfLogicalProcessors : 16
MaxClockSpeed             : 3201
L2CacheSize               : 4096
L3CacheSize               : 16384



PS C:\Users\mikew> # Total RAM
PS C:\Users\mikew> (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
15.3417091369629
PS C:\Users\mikew>
PS C:\Users\mikew> # RAM sticks
PS C:\Users\mikew> Get-CimInstance Win32_PhysicalMemory | Select-Object `
>>   BankLabel, Capacity, Speed, ConfiguredClockSpeed, Manufacturer, PartNumber, SerialNumber


BankLabel            : P0 CHANNEL A
Capacity             : 8589934592
Speed                : 3200
ConfiguredClockSpeed : 3200
Manufacturer         : Hynix
PartNumber           : HMA81GS6DJR8N-XN
SerialNumber         : 86197A7C

BankLabel            : P0 CHANNEL B
Capacity             : 8589934592
Speed                : 3200
ConfiguredClockSpeed : 3200
Manufacturer         : Hynix
PartNumber           : HMA81GS6DJR8N-XN
SerialNumber         : 86197A7B



PS C:\Users\mikew> Get-CimInstance Win32_VideoController | Select-Object `
>>   Name, AdapterRAM, DriverVersion, VideoProcessor, CurrentHorizontalResolution, CurrentVerticalResolution


Name                        : AMD Radeon(TM) Graphics
AdapterRAM                  : 536870912
DriverVersion               : 31.0.21914.8004
VideoProcessor              : AMD Radeon Graphics Processor (0x1638)
CurrentHorizontalResolution : 1920
CurrentVerticalResolution   : 1080

Name                        : NVIDIA GeForce RTX 3050 Ti Laptop GPU
AdapterRAM                  : 4293918720
DriverVersion               : 32.0.15.7703
VideoProcessor              : NVIDIA GeForce RTX 3050 Ti Laptop GPU
CurrentHorizontalResolution : 4096
CurrentVerticalResolution   : 2160



PS C:\Users\mikew>


PS C:\Users\mikew> Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size, HealthStatus

FriendlyName      MediaType          Size HealthStatus
------------      ---------          ---- ------------
WD Blue SN570 2TB SSD       2000398934016 Healthy


PS C:\Users\mikew>
PS C:\Users\mikew> Get-Disk | Select-Object Number, FriendlyName, BusType, PartitionStyle, Size


Number         : 0
FriendlyName   : WD Blue SN570 2TB
BusType        : NVMe
PartitionStyle : GPT
Size           : 2000398934016

Number         : 2
FriendlyName   : Generic- SD/MMC/MS/MSPRO
BusType        : USB
PartitionStyle : RAW
Size           : 0

Number         : 1
FriendlyName   : Generic- SD/MMC
BusType        : USB
PartitionStyle : RAW
Size           : 0



PS C:\Users\mikew>
PS C:\Users\mikew> Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining


DriveLetter     :
FileSystemLabel :
FileSystem      : NTFS
Size            : 765456384
SizeRemaining   : 104034304

DriveLetter     : C
FileSystemLabel : Windows
FileSystem      : NTFS
Size            : 1998829121536
SizeRemaining   : 1791844651008

DriveLetter     : D
FileSystemLabel :
FileSystem      :
Size            : 0
SizeRemaining   : 0

DriveLetter     : E
FileSystemLabel :
FileSystem      :
Size            : 0
SizeRemaining   : 0

DriveLetter     :
FileSystemLabel : SYSTEM
FileSystem      : FAT32
Size            : 100663296
SizeRemaining   : 65169408

DriveLetter     :
FileSystemLabel : Windows RE tools
FileSystem      : NTFS
Size            : 680521728
SizeRemaining   : 120655872



PS C:\Users\mikew>