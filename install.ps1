#Requires -Version 5.1
 $ErrorActionPreference = 'Stop'

# Каталог bin рядом с самим скриптом (аналог BASH_SOURCE[0] из bash-версии)
 $BinDir = Join-Path $PSScriptRoot 'bin'

if (-not (Test-Path $BinDir)) {
    throw "Каталог не найден: $BinDir"
}

# --- 1. PATH для текущей сессии ---
if (($env:Path -split ';') -notcontains $BinDir) {
    $env:Path = "$BinDir;$env:Path"
}

# --- 2. PATH навсегда (HKCU\Environment) ---
# Читаем "сырое" значение, НЕ раскрывая %переменные%, и пишем как REG_EXPAND_SZ,
# чтобы не сломать соседние записи вида %USERPROFILE%\...
 $regKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
try {
    $userPath = $regKey.GetValue('Path', '',
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

    if (($userPath -split ';') -contains $BinDir) {
        Write-Host "Уже прописано в пользовательском PATH: $BinDir" -ForegroundColor Yellow
    } else {
        $newPath = if ($userPath) { "$BinDir;$userPath" } else { $BinDir }
        $regKey.SetValue('Path', $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
        Write-Host "Добавлено в пользовательский PATH: $BinDir" -ForegroundColor Green
    }
} finally {
    $regKey.Close()
}

# --- 3. Сообщаем системе об изменении окружения (иначе без перелогина не подхватится) ---
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

Write-Host "`nГотово. В новом окне терминала проверьте: Get-Command omp-run"