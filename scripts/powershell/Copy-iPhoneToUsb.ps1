<#
Copy-iPhoneToUsb.ps1
- Lists items visible from a connected iPhone via Windows Shell namespace (usually DCIM photos/videos)
- Copies everything it can see to a destination folder (e.g., USB drive)

Important realities:
- Windows does NOT expose the whole iPhone filesystem.
- You usually only get Internal Storage -> DCIM (photos/videos).
- This uses Explorer’s copy engine via Shell.Application.CopyHere().
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Get-FolderFromItem {
    param(
        [Parameter(Mandatory)]
        [object] $Shell,      # Shell.Application COM object
        [Parameter(Mandatory)]
        [object] $Item        # FolderItem COM object
    )
    # NameSpace() can accept a FolderItem and returns a Folder
    $f = $Shell.NameSpace($Item)
    return $f
}

function Get-ChildItemByName {
    param(
        [Parameter(Mandatory)]
        [object] $Folder,     # Shell.Folder
        [Parameter(Mandatory)]
        [string] $Name
    )
    foreach ($it in @($Folder.Items())) {
        if ($it.Name -eq $Name) { return $it }
    }
    return $null
}

function Get-ShellFolderByPathParts {
    param(
        [Parameter(Mandatory)]
        [object] $Shell,          # Shell.Application
        [Parameter(Mandatory)]
        [object] $RootFolder,     # Shell.Folder
        [Parameter(Mandatory)]
        [string[]] $PathParts     # e.g. @("Internal Storage","DCIM")
    )

    $currentFolder = $RootFolder
    foreach ($part in $PathParts) {
        $nextItem = Get-ChildItemByName -Folder $currentFolder -Name $part
        if (-not $nextItem) { return $null }

        $nextFolder = Get-FolderFromItem -Shell $Shell -Item $nextItem
        if (-not $nextFolder) { return $null }

        $currentFolder = $nextFolder
    }
    return $currentFolder
}

function Enumerate-ShellItemsRecursive {
    param(
        [Parameter(Mandatory)]
        [object] $Shell,          # Shell.Application
        [Parameter(Mandatory)]
        [object] $Folder,         # Shell.Folder
        [Parameter(Mandatory)]
        [string] $VirtualPath
    )

    foreach ($item in @($Folder.Items())) {
        $isFolder = $item.IsFolder
        $pathHere = Join-Path $VirtualPath $item.Name

        [pscustomobject]@{
            Name        = $item.Name
            VirtualPath = $pathHere
            IsFolder    = $isFolder
        }

        if ($isFolder) {
            $subFolder = Get-FolderFromItem -Shell $Shell -Item $item
            if ($subFolder) {
                Enumerate-ShellItemsRecursive -Shell $Shell -Folder $subFolder -VirtualPath $pathHere
            }
        }
    }
}

function Copy-ShellFolderToDisk {
    param(
        [Parameter(Mandatory)]
        [object] $Shell,          # Shell.Application
        [Parameter(Mandatory)]
        [object] $SourceFolder,   # Shell.Folder
        [Parameter(Mandatory)]
        [string] $DestPath,
        [string] $VirtualLabel = "iPhone"
    )

    Ensure-Directory -Path $DestPath

    # CopyHere flags:
    # 0x10  No UI (best-effort)
    # 0x200 No error UI
    # 0x400 Yes to all
    $copyFlags = 0x10 + 0x200 + 0x400

    $destFolder = $Shell.NameSpace($DestPath)
    if (-not $destFolder) { throw "Destination '$DestPath' is not accessible via Shell." }

    Write-Host "Copying '$VirtualLabel' -> '$DestPath' ..."
    $destFolder.CopyHere($SourceFolder.Items(), $copyFlags)

    Write-Host "Copy started (Explorer copy engine). Leave this window open until it finishes."
}

# ----------------- MAIN -----------------

Write-Host "Make sure iPhone is UNLOCKED and you tapped Trust/Allow." -ForegroundColor Cyan

$destRoot = Read-Host "Enter destination folder on USB (example: E:\iPhoneBackup)"
if ([string]::IsNullOrWhiteSpace($destRoot)) { throw "Destination cannot be empty." }
Ensure-Directory -Path $destRoot

$shell = New-Object -ComObject Shell.Application

# 17 = ssfDRIVES ("This PC" / "Computer")
$thisPC = $shell.NameSpace(17)
if (-not $thisPC) { throw "Could not open 'This PC' (ssfDRIVES=17) via Shell.NameSpace()." }

$deviceNameHint = Read-Host "Enter iPhone device name as shown in File Explorer (press Enter to search for 'iPhone')"
if ([string]::IsNullOrWhiteSpace($deviceNameHint)) { $deviceNameHint = "iPhone" }

$iphoneItem = $null
foreach ($item in @($thisPC.Items())) {
    if ($item.Name -like "*$deviceNameHint*") { $iphoneItem = $item; break }
}

if (-not $iphoneItem) {
    Write-Host "`nDevices under This PC:" -ForegroundColor Yellow
    @($thisPC.Items()) | ForEach-Object { Write-Host " - $($_.Name)" }
    throw "Could not find a device matching '*$deviceNameHint*'. Unlock iPhone + tap Trust, then re-run."
}

$iphoneFolder = Get-FolderFromItem -Shell $shell -Item $iphoneItem
if (-not $iphoneFolder) { throw "Could not open iPhone device folder via Shell.NameSpace(item)." }

# Typical iPhone path in Windows Explorer:
#   <iPhone> -> Internal Storage -> DCIM
$dcimFolder = Get-ShellFolderByPathParts -Shell $shell -RootFolder $iphoneFolder -PathParts @("Internal Storage", "DCIM")

if (-not $dcimFolder) {
    Write-Host "`nCouldn't find Internal Storage\DCIM. Listing what IS visible at device root..." -ForegroundColor Yellow

    $visible = Enumerate-ShellItemsRecursive -Shell $shell -Folder $iphoneFolder -VirtualPath $iphoneItem.Name
    $txt = Join-Path $destRoot "VISIBLE_ITEMS.txt"
    $csv = Join-Path $destRoot "VISIBLE_ITEMS.csv"

    $visible | Sort-Object VirtualPath | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
    $visible | Sort-Object VirtualPath | Format-Table -AutoSize | Out-String | Set-Content -Encoding UTF8 $txt

    Write-Host "Wrote visible items list to:"
    Write-Host " - $txt"
    Write-Host " - $csv"

    throw "DCIM not found. iPhone may not be trusted/unlocked, or Windows Apple device support is not working."
}

Write-Host "`nEnumerating DCIM..." -ForegroundColor Cyan
$items = Enumerate-ShellItemsRecursive -Shell $shell -Folder $dcimFolder -VirtualPath (Join-Path $iphoneItem.Name "Internal Storage\DCIM")

$dcimListTxt = Join-Path $destRoot "DCIM_FILE_LIST.txt"
$dcimListCsv = Join-Path $destRoot "DCIM_FILE_LIST.csv"

$items | Sort-Object VirtualPath | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $dcimListCsv
$items | Sort-Object VirtualPath | Format-Table -AutoSize | Out-String | Set-Content -Encoding UTF8 $dcimListTxt

Write-Host "Wrote DCIM lists:"
Write-Host " - $dcimListTxt"
Write-Host " - $dcimListCsv"

$dcimDest = Join-Path $destRoot "DCIM"
Copy-ShellFolderToDisk -Shell $shell -SourceFolder $dcimFolder -DestPath $dcimDest -VirtualLabel "DCIM (Photos/Videos)"

Write-Host "`nDone." -ForegroundColor Green
