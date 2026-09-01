#Requires -Version 5.1
 $ErrorActionPreference = 'Stop'

 $BinDir = Join-Path $PSScriptRoot 'bin'

# Нормализация для сравнения: без хвостовых слешей, без учёта регистра
 $target = $BinDir.TrimEnd('\', '/')

# --- 1. Удаляем из постоянного PATH (HKCU\Environment) ---
 $regKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
try {
    $userPath = $regKey.GetValue('Path', '',
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    $entries = @($userPath -split ';' | Where-Object { $_ })
    $removed = @($entries | Where-Object { $_.TrimEnd('\', '/') -ieq $target })
    $kept    = @($entries | Where-Object { $_.TrimEnd('\', '/') -ine $target })

    if ($removed.Count -eq 0) {
        Write-Host "В пользовательском PATH нет записей: $BinDir" -ForegroundColor Yellow
    } else {
        # Бэкап прежнего значения на случай отката
        $backup = Join-Path $env:TEMP ("user-path-backup-{0:yyyyMMddHHmmss}.txt" -f (Get-Date))
        Set-Content -Path $backup -Value $userPath -Encoding UTF8

        if ($kept.Count -eq 0) {
            $regKey.DeleteValue('Path')   # PATH опустел — удаляем значение целиком
        } else {
            $regKey.SetValue('Path', ($kept -join ';'),
                [Microsoft.Win32.RegistryValueKind]::ExpandString)
        }
        Write-Host "Удалено из пользовательского PATH: $($removed -join '; ')" -ForegroundColor Green
        Write-Host "Бэкап прежнего значения: $backup"
    }
} finally {
    $regKey.Close()
}

# --- 2. Убираем из PATH текущей сессии ---
 $env:Path = (($env:Path -split ';') |
    Where-Object { $_ -and ($_.TrimEnd('\', '/') -ine $target) }) -join ';'

# --- 3. Broadcast WM_SETTINGCHANGE (как в install.ps1) ---
if (-not ('Win32.NativeMethods' -as [type])) {
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
}
 $HWND_BROADCAST   = [IntPtr]0xFFFF
 $WM_SETTINGCHANGE = 0x1A
 $SMTO_ABORTIFHUNG = 0x0002
[UIntPtr]$res = [UIntPtr]::Zero
[Win32.NativeMethods]::SendMessageTimeout(
    $HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero,
    'Environment', $SMTO_ABORTIFHUNG, 5000, [ref]$res) | Out-Null

Write-Host "`nГотово. Проверка в новом окне: Get-Command omp-run (должна быть не найдена)"