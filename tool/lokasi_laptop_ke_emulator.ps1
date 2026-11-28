<#
.SYNOPSIS
  Kirim lokasi laptop (Windows Location) ke GPS emulator Android.

.DESCRIPTION
  Emulator Android punya GPS virtual sendiri dan tidak membaca lokasi laptop.
  Skrip ini membaca lokasi dari Windows (Wi-Fi/GPS laptop) lalu mengirimkannya
  ke emulator lewat `adb emu geo fix`, sehingga halaman Tombol Hadir memakai
  posisi laptop Anda. Semua berjalan lokal; lokasi tidak dikirim ke layanan luar.

  Syarat: Windows Settings > Privacy & security > Location:
    - "Location services" ON
    - "Let desktop apps access your location" ON

.PARAMETER Ulang
  Jalankan terus dan kirim ulang lokasi setiap N detik (0 = sekali saja).

.PARAMETER Perangkat
  Serial emulator (bawaan: emulator pertama yang terhubung).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\lokasi_laptop_ke_emulator.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\lokasi_laptop_ke_emulator.ps1 -Ulang 30
#>
param(
    [int]$Ulang = 0,
    [string]$Perangkat = ''
)

$ErrorActionPreference = 'Stop'
$inv = [System.Globalization.CultureInfo]::InvariantCulture

function Find-Adb {
    $root = Split-Path -Parent $PSScriptRoot
    $props = Join-Path $root 'android\local.properties'
    $candidates = @()
    if (Test-Path $props) {
        $line = Select-String -Path $props -Pattern '^sdk\.dir=' | Select-Object -First 1
        if ($line) {
            $sdk = ($line.Line -replace '^sdk\.dir=', '') -replace '\\\\', '\' -replace '\\:', ':'
            $candidates += (Join-Path $sdk 'platform-tools\adb.exe')
        }
    }
    foreach ($v in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk'))) {
        if ($v) { $candidates += (Join-Path $v 'platform-tools\adb.exe') }
    }
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'adb.exe tidak ditemukan. Isi sdk.dir di android\local.properties atau set ANDROID_HOME.'
}

function Get-LaptopLocation {
    Add-Type -AssemblyName System.Device
    $watcher = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
    try {
        $null = $watcher.TryStart($false, [TimeSpan]::FromSeconds(5))
        $deadline = (Get-Date).AddSeconds(20)
        while ((Get-Date) -lt $deadline) {
            if ($watcher.Permission -eq 'Denied') {
                throw 'Akses lokasi Windows ditolak. Aktifkan Location services dan "Let desktop apps access your location".'
            }
            $loc = $watcher.Position.Location
            if ($watcher.Status -eq 'Ready' -and -not $loc.IsUnknown) { return $loc }
            Start-Sleep -Milliseconds 500
        }
        throw 'Lokasi laptop belum tersedia (status: ' + $watcher.Status + '). Pastikan Wi-Fi/lokasi Windows aktif.'
    } finally {
        $watcher.Stop()
        $watcher.Dispose()
    }
}

$adb = Find-Adb
if (-not $Perangkat) {
    $Perangkat = (& $adb devices | Select-String -Pattern '^(emulator-\d+)\s+device' | Select-Object -First 1).Matches.Groups[1].Value
    if (-not $Perangkat) { throw 'Tidak ada emulator yang berjalan (adb devices).' }
}

do {
    $loc = Get-LaptopLocation
    $lat = $loc.Latitude.ToString('0.000000', $inv)
    $lng = $loc.Longitude.ToString('0.000000', $inv)
    $acc = [math]::Round($loc.HorizontalAccuracy)
    # Perhatikan urutan: geo fix <longitude> <latitude>
    $out = & $adb -s $Perangkat emu geo fix $lng $lat 2>&1
    $waktu = (Get-Date).ToString('HH:mm:ss')
    if ("$out" -match 'OK') {
        Write-Output "[$waktu] Lokasi laptop dikirim ke $Perangkat : $lat, $lng (akurasi laptop +/- $acc m)"
    } else {
        Write-Output "[$waktu] Gagal mengirim ke ${Perangkat}: $out"
    }
    if ($acc -gt 100) {
        Write-Output '  Catatan: lokasi laptop berasal dari Wi-Fi/IP dan bisa meleset > 100 m dari posisi sebenarnya.'
        Write-Output '  Emulator tetap melaporkan akurasi +/- 5 m ke aplikasi. Untuk uji akurat, pakai HP Android asli.'
    }
    if ($Ulang -gt 0) { Start-Sleep -Seconds $Ulang }
} while ($Ulang -gt 0)
