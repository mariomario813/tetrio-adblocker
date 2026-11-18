param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$rules = @(
    'MAP *.pub.network ~NOTFOUND',
    'MAP *.doubleclick.net ~NOTFOUND',
    'MAP *.googlesyndication.com ~NOTFOUND',
    'MAP *.googleadservices.com ~NOTFOUND',
    'MAP adservice.google.com ~NOTFOUND',
    'MAP fundingchoicesmessages.google.com ~NOTFOUND',
    'MAP www.googletagservices.com ~NOTFOUND',
    'MAP *.amazon-adsystem.com ~NOTFOUND',
    'MAP *.rubiconproject.com ~NOTFOUND',
    'MAP *.pubmatic.com ~NOTFOUND',
    'MAP *.adnxs.com ~NOTFOUND',
    'MAP *.casalemedia.com ~NOTFOUND',
    'MAP *.3lift.com ~NOTFOUND',
    'MAP *.criteo.com ~NOTFOUND',
    'MAP *.criteo.net ~NOTFOUND',
    'MAP *.yieldmo.com ~NOTFOUND',
    'MAP *.outbrain.com ~NOTFOUND',
    'MAP *.taboola.com ~NOTFOUND',
    'MAP btloader.com ~NOTFOUND',
    'MAP api.btloader.com ~NOTFOUND',
    'MAP cdn.confiant-integrations.net ~NOTFOUND',
    'MAP cdn.intergient.com ~NOTFOUND',
    'MAP cdn.fuseplatform.net ~NOTFOUND',
    'MAP player.anyclip.com ~NOTFOUND'
) -join ', '

$flag = '--host-resolver-rules="' + $rules + '"'

function Get-TetrioExe {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\tetrio-desktop\TETR.IO.exe'),
        (Join-Path $env:ProgramFiles 'tetrio-desktop\TETR.IO.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'tetrio-desktop\TETR.IO.exe')
    )
    $uninstallKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($key in $uninstallKeys) {
        Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like 'TETR.IO*' -and $_.InstallLocation } |
            ForEach-Object { $candidates += Join-Path $_.InstallLocation 'TETR.IO.exe' }
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

function Get-ShortcutPaths {
    $dirs = @(
        (Join-Path $env:USERPROFILE 'Desktop'),
        (Join-Path $env:PUBLIC 'Desktop'),
        (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'),
        (Join-Path $env:PROGRAMDATA 'Microsoft\Windows\Start Menu\Programs'),
        (Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar')
    )
    $paths = @()
    foreach ($d in $dirs) {
        if (Test-Path -LiteralPath $d) {
            $paths += Get-ChildItem -LiteralPath $d -Filter '*.lnk' -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName
        }
    }
    return $paths | Select-Object -Unique
}

function Update-ArgsString {
    param([string]$Value)
    $clean = $Value -replace '--host-resolver-rules="[^"]*"', ''
    $clean = $clean -replace '--host-resolver-rules=\S+', ''
    $clean = $clean.Trim()
    if ($Uninstall) { return $clean }
    if ($clean) { return "$clean $flag" }
    return $flag
}

function Update-Protocol {
    param([string]$Exe)
    $regPath = 'HKCU:\Software\Classes\tetrio\shell\open\command'
    $existing = Get-ItemProperty -LiteralPath $regPath -Name '(default)' -ErrorAction SilentlyContinue
    if ($existing) {
        $cmd = [string]$existing.'(default)'
    } else {
        $cmd = '"' + $Exe + '" "%1"'
    }
    $clean = $cmd -replace '--host-resolver-rules="[^"]*"', ''
    $clean = $clean -replace '--host-resolver-rules=\S+', ''
    $clean = $clean.TrimEnd()

    if ($Uninstall) {
        if (Test-Path -LiteralPath $regPath) {
            Set-ItemProperty -LiteralPath $regPath -Name '(default)' -Value $clean
        }
        return 'Protocol handler restored'
    }

    if ($clean -match '"%1"') {
        $new = [regex]::Replace($clean, '"%1"', { param($m) $m.Value + ' ' + $flag })
    } elseif ($clean -match '%1') {
        $new = [regex]::Replace($clean, '%1', { param($m) $m.Value + ' ' + $flag })
    } else {
        $new = $clean + ' ' + $flag
    }

    if (-not (Test-Path -LiteralPath $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -LiteralPath $regPath -Name '(default)' -Value $new
    return 'Protocol handler patched'
}

$exe = Get-TetrioExe
if (-not $exe) {
    Write-Output 'TETR.IO.exe not found. Install TETR.IO Desktop first.'
    exit 1
}

$w = New-Object -ComObject WScript.Shell
$count = 0
foreach ($p in Get-ShortcutPaths) {
    $s = $w.CreateShortcut($p)
    if ([string]::IsNullOrEmpty($s.TargetPath)) { continue }
    if ([string]::Compare($s.TargetPath, $exe, $true) -ne 0) { continue }
    $s.Arguments = Update-ArgsString -Value $s.Arguments
    $s.Save()
    $count++
    if ($Uninstall) { Write-Output "Restored: $p" } else { Write-Output "Patched: $p" }
}

Write-Output (Update-Protocol -Exe $exe)
Write-Output "Executable: $exe"
Write-Output "Shortcuts processed: $count"
if ($Uninstall) {
    Write-Output 'Ad blocking removed.'
} else {
    Write-Output 'Ad domains now fail to resolve for TETR.IO.'
}
