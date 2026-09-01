@echo off
:: Переключаем кодировку консоли на UTF-8 для корректного вывода текста
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Собираем все аргументы в одну строку
set "ARGS= %* "

:: Проверяем, переданы ли аргументы вообще
if "%~1" == "" (
    echo Использование: %~nx0 [core] [tools] [harness] [all]
    echo Пример:       %~nx0 core tools
    exit /b 1
)

:: Если передано слово "all", активируем все три сборки
echo %ARGS% | findstr /i " all " >nul
if %errorlevel% equ 0 set "ARGS= core tools harness "

:: ====================================================
:: 1. Сборка CORE (Первая в очереди)
:: ====================================================
echo %ARGS% | findstr /i " core " >nul
if %errorlevel% equ 0 (
    echo ====================================================
    echo Сборка [1/3]: localhost/aerovato/container-v3-core:latest
    echo ====================================================
    docker build -f .\Dockerfile.Core -t localhost/aerovato/container-v3-core:latest .
    if !errorlevel! neq 0 (echo [ОШИБКА] Сборка Core завершилась неудачно. & exit /b !errorlevel!)
)

:: ====================================================
:: 2. Сборка TOOLS (Вторая в очереди)
:: ====================================================
echo %ARGS% | findstr /i " tools " >nul
if %errorlevel% equ 0 (
    echo ====================================================
    echo Сборка [2/3]: localhost/aerovato/container-v3-tools:latest
    echo ====================================================
    docker build -f .\Dockerfile.Tools -t localhost/aerovato/container-v3-tools:latest .
    if !errorlevel! neq 0 (echo [ОШИБКА] Сборка Tools завершилась неудачно. & exit /b !errorlevel!)
)

:: ====================================================
:: 3. Сборка HARNESS (Третья в очереди)
:: ====================================================
echo %ARGS% | findstr /i " harness " >nul
if %errorlevel% equ 0 (
    echo ====================================================
    echo Сборка [3/3]: localhost/aerovato/container-v3-harness:latest
    echo ====================================================
    docker build -f .\Dockerfile.Harness -t localhost/aerovato/container-v3-harness:latest .
    if !errorlevel! neq 0 (echo [ОШИБКА] Сборка Harness завершилась неудачно. & exit /b !errorlevel!)
)

echo ====================================================
echo [УСПЕХ] Все выбранные сборки завершены.
echo ====================================================
