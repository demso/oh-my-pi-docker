param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$WorkPath
)

# Обратные слеши Windows -> прямые для Linux-контейнера
 $LinuxPath = $WorkPath -replace '\\', '/'

# Фолбэк для TERM (в PowerShell переменные окружения живут в $env:)
 $term = if ($env:TERM) { $env:TERM } else { 'xterm-256color' }

docker exec -it `
    -e "TERM=$term" `
    -e COLORTERM=truecolor `
    -w "$LinuxPath" `
    omp-container omp -c