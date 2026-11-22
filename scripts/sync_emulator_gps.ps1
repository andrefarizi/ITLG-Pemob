# Sinkronisasi otomatis lokasi nyata laptop Windows (Windows Location Service)
# ke Android Emulator agar GPS emulator selalu mengikuti perpindahan lokasi laptop.
param(
    [string]$AdbPath = "C:\src\Android\Sdk\platform-tools\adb.exe",
    [int]$IntervalSeconds = 10
)

Add-Type -AssemblyName System.Device
$watcher = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
$watcher.Start()

$lastLat = $null
$lastLng = $null

Write-Output "[GPS Sync] Memantau lokasi Windows Location Service untuk Android Emulator..."

try {
    while ($true) {
        $loc = $watcher.Position.Location
        if ($loc -ne $null -and -not $loc.IsUnknown) {
            $lat = [math]::Round($loc.Latitude, 6)
            $lng = [math]::Round($loc.Longitude, 6)

            $changed = ($lastLat -eq $null) -or
                ([math]::Abs($lat - $lastLat) -gt 0.00005) -or
                ([math]::Abs($lng - $lastLng) -gt 0.00005)

            if ($changed -and (Test-Path $AdbPath)) {
                $devices = & $AdbPath devices 2>$null
                foreach ($line in $devices) {
                    if ($line -match "^(emulator-\d+)\s+device$") {
                        $emu = $matches[1]
                        & $AdbPath -s $emu emu geo fix $lng $lat | Out-Null
                        Write-Output "[GPS Sync] $(Get-Date -Format 'HH:mm:ss') -> $emu updated to lat=$lat, lng=$lng (acc=±$([math]::Round($loc.HorizontalAccuracy))m)"
                    }
                }
                $lastLat = $lat
                $lastLng = $lng
            }
        }
        Start-Sleep -Seconds $IntervalSeconds
    }
} finally {
    $watcher.Stop()
}
