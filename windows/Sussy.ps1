Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ScriptPath = Join-Path $PSScriptRoot "Sussy.ps1"

$Extension = ".sls"

$ProgId = "SUSSY.SLS"

$ExtensionKey = "HKCU:\Software\Classes\.sls"

$ProgIdKey = "HKCU:\Software\Classes\SUSSY.SLS"

$CommandKey = "HKCU:\Software\Classes\SUSSY.SLS\shell\open\command"

$IconKey = "HKCU:\Software\Classes\SUSSY.SLS\DefaultIcon"

if (-not (Test-Path -LiteralPath $ScriptPath)) {

    Write-Host ""
    Write-Host "ВНИМАНИЕ!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Sussy.ps1 не найден по пути:" -ForegroundColor Red
    Write-Host $ScriptPath -ForegroundColor Red
    Write-Host ""
}

function Select-Folder {

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog

    $dialog.Description = "Выберите папку"
    $dialog.ShowNewFolderButton = $true

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {

        return $dialog.SelectedPath
    }

    return $null
}

function Select-SLSFile {

    $dialog = New-Object System.Windows.Forms.OpenFileDialog

    $dialog.Title = "Выберите SLS-архив"

    $dialog.Filter = `
        "SLS архив (*.sls)|*.sls|Все файлы (*.*)|*.*"

    $dialog.Multiselect = $false

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {

        return $dialog.FileName
    }

    return $null
}

function Archive-Folder {
    Write-Host "если вы не видите меню выбора папки, сверните все окна" -ForegroundColor Red
    $sourceFolder = Select-Folder

    if (-not $sourceFolder) {

        Write-Host ""
        Write-Host "Папка не выбрана." -ForegroundColor Yellow

        return
    }


    $parentFolder = Split-Path $sourceFolder -Parent

    $folderName = Split-Path $sourceFolder -Leaf


    $slsFile = Join-Path `
        $parentFolder `
        "$folderName.sls"


    if (Test-Path -LiteralPath $slsFile) {

        Remove-Item `
            -LiteralPath $slsFile `
            -Force
    }


    Write-Host ""
    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host "             АРХИВАЦИЯ" `
        -ForegroundColor Cyan

    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "Источник:"
    Write-Host $sourceFolder -ForegroundColor Yellow

    Write-Host ""


    try {

        
        $files = Get-ChildItem `
            -LiteralPath $sourceFolder `
            -File `
            -Recurse `
            -Force `
            -ErrorAction Stop


        $totalFiles = $files.Count

        if ($totalFiles -eq 0) {

            
            $archive = [System.IO.Compression.ZipFile]::Open(
                $slsFile,
                [System.IO.Compression.ZipArchiveMode]::Create
            )

            $archive.Dispose()

            Write-Host ""
            Write-Host "Готово!" -ForegroundColor Green

            Write-Host ""
            Write-Host "SLS-архив:"
            Write-Host $slsFile -ForegroundColor Green

            return
        }


        
        $archive = [System.IO.Compression.ZipFile]::Open(
            $slsFile,
            [System.IO.Compression.ZipArchiveMode]::Create
        )


        try {

            $currentFile = 0

            foreach ($file in $files) {

                $currentFile++


                
                $relativePath = $file.FullName.Substring(
                    $sourceFolder.Length
                ).TrimStart(
                    [System.IO.Path]::DirectorySeparatorChar,
                    [System.IO.Path]::AltDirectorySeparatorChar
                )


                
                $entry = $archive.CreateEntry(
                    $relativePath,
                    [System.IO.Compression.CompressionLevel]::Optimal
                )


                $inputStream = $null
                $outputStream = $null

                try {

                    $inputStream = $file.OpenRead()

                    $outputStream = $entry.Open()

                    $inputStream.CopyTo($outputStream)

                }
                finally {

                    if ($outputStream) {
                        $outputStream.Dispose()
                    }

                    if ($inputStream) {
                        $inputStream.Dispose()
                    }
                }


                
                $percent = [int](($currentFile / $totalFiles) * 100)

                Write-Progress `
                    -Activity "Архивация" `
                    -Status "$percent%" `
                    -PercentComplete $percent
            }

        }
        finally {

            $archive.Dispose()

            Write-Progress `
                -Activity "Архивация" `
                -Completed
        }


        Write-Host ""
        Write-Host "Готово!" -ForegroundColor Green

        Write-Host ""

        Write-Host "SLS-архив:"
        Write-Host $slsFile -ForegroundColor Green
    }
    catch {

        Write-Progress `
            -Activity "Архивация" `
            -Completed

        Write-Host ""
        Write-Host "Ошибка при архивации:" -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Red


        if (Test-Path -LiteralPath $slsFile) {

            Remove-Item `
                -LiteralPath $slsFile `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}

function Extract-SLS {

    param(
        [string]$InputFile = $null
    )


    if ($InputFile) {

        $slsFile = $InputFile


        if (-not (Test-Path -LiteralPath $slsFile)) {

            Write-Host ""
            Write-Host "Файл не найден:" -ForegroundColor Red
            Write-Host $slsFile -ForegroundColor Red

            return
        }
    }
    else {

        $slsFile = Select-SLSFile


        if (-not $slsFile) {

            Write-Host ""
            Write-Host "Файл не выбран." -ForegroundColor Yellow

            return
        }
    }


    $destinationFolder = Select-Folder


    if (-not $destinationFolder) {

        Write-Host ""
        Write-Host "Папка назначения не выбрана." `
            -ForegroundColor Yellow

        return
    }


    Write-Host ""
    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host "            РАСПАКОВКА" `
        -ForegroundColor Cyan

    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "Архив:"
    Write-Host $slsFile -ForegroundColor Yellow

    Write-Host ""

    Write-Host "Назначение:"
    Write-Host $destinationFolder -ForegroundColor Yellow

    Write-Host ""


    try {

        
        $archive = [System.IO.Compression.ZipFile]::OpenRead(
            $slsFile
        )


        try {

            $entries = $archive.Entries

            $totalFiles = $entries.Count
            $currentFile = 0


            foreach ($entry in $entries) {

                $currentFile++


                
                $destinationPath = Join-Path `
                    $destinationFolder `
                    $entry.FullName


                
                $fullDestinationFolder = (
                    [System.IO.Path]::GetFullPath(
                        $destinationFolder
                    )
                ).TrimEnd(
                    [System.IO.Path]::DirectorySeparatorChar
                ) + [System.IO.Path]::DirectorySeparatorChar


                $fullDestinationPath = (
                    [System.IO.Path]::GetFullPath(
                        $destinationPath
                    )
                )


                if (-not $fullDestinationPath.StartsWith(
                    $fullDestinationFolder,
                    [System.StringComparison]::OrdinalIgnoreCase
                )) {

                    throw "Обнаружен недопустимый путь в архиве: $($entry.FullName)"
                }


                
                if ([string]::IsNullOrEmpty($entry.Name)) {

                    [System.IO.Directory]::CreateDirectory(
                        $fullDestinationPath
                    ) | Out-Null

                }
                else {

                    
                    $parent = Split-Path `
                        $fullDestinationPath `
                        -Parent


                    if ($parent) {

                        [System.IO.Directory]::CreateDirectory(
                            $parent
                        ) | Out-Null
                    }


                    
                    $inputStream = $null
                    $outputStream = $null

                    try {

                        $inputStream = $entry.Open()

                        $outputStream = [System.IO.File]::Create(
                            $fullDestinationPath
                        )

                        $inputStream.CopyTo(
                            $outputStream
                        )

                    }
                    finally {

                        if ($outputStream) {
                            $outputStream.Dispose()
                        }

                        if ($inputStream) {
                            $inputStream.Dispose()
                        }
                    }
                }


                
                if ($totalFiles -gt 0) {

                    $percent = [int](
                        ($currentFile / $totalFiles) * 100
                    )

                    Write-Progress `
                        -Activity "Распаковка" `
                        -Status "$percent%" `
                        -PercentComplete $percent
                }
            }

        }
        finally {

            $archive.Dispose()

            Write-Progress `
                -Activity "Распаковка" `
                -Completed
        }


        Write-Host ""
        Write-Host "Готово!" -ForegroundColor Green

        Write-Host ""

        Write-Host "Файлы распакованы в:"
        Write-Host $destinationFolder -ForegroundColor Green
    }
    catch { 

        Write-Progress `
        -Activity "Распаковка" `
        -Completed

        Write-Host "" 
        Write-Host "Ошибка при распаковке:" -ForegroundColor Red 

        Write-Host $_.Exception.Message -ForegroundColor Red 
    }
}
function Refresh-Explorer {

    $signature = @'
using System;
using System.Runtime.InteropServices;

public static class SussyExplorer
{
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(
        uint wEventId,
        uint uFlags,
        IntPtr dwItem1,
        IntPtr dwItem2
    );
}
'@


    try {

        if (-not ("SussyExplorer" -as [type])) {

            Add-Type -TypeDefinition $signature
        }


        [SussyExplorer]::SHChangeNotify(
            0x08000000,
            0x0000,
            [IntPtr]::Zero,
            [IntPtr]::Zero
        )
    }
    catch {
    }
}

function Test-SLSAssociation {

    if (-not (Test-Path -LiteralPath $ExtensionKey)) {

        return $false
    }


    try {

        $value = (
            Get-ItemProperty `
                -Path $ExtensionKey `
                -Name "(default)" `
                -ErrorAction Stop
        )."(default)"


        return ($value -eq $ProgId)
    }
    catch {

        return $false
    }
}

function Register-Association {

    $isAssociated = Test-SLSAssociation


    Write-Host ""
    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host "          SLS ASSOCIATION" `
        -ForegroundColor Cyan

    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host ""
    Write-Host "ОТКАЗ ОТ ОТВЕТСТВЕННОСТИ" -ForegroundColor Yellow
    Write-Host "" 
    Write-Host "ТЕХНИКА БЕЗОПАСНОСТИ:" -ForegroundColor Yellow
    Write-Host "НИ В КОЕМ СЛУЧАЕ ПОСЛЕ УСТАНОВКИ АССОЦИАЦИИ НЕ МЕНЯЙТЕ РАСПОЛОЖЕНИЕ СКРИПТА." -ForegroundColor Red
    Write-Host "если вам нужно переместить вайл, сначала УДАЛИТЕ ассоциацию. если вы не сделали этого, могут быть технические последствия" -ForegroundColor Yellow
    Write-Host "ЗА ТЕХНИЧЕСКИЕ ПОСЛДЕДСТВИЯ, ПРИЧИНЁНЫЕ ПО НАРУШЕНИИ ТЕХНИКИ БЕЗОПАСНОСТИ ВАМИ, ПРОИЗВОДИТЕЛЬ ОТВЕТСТВЕННОСТИ НЕ НЕСЁТ!!!" -ForegroundColor Red
    Write-Host "ЕСЛИ МЫ НАРУШИЛИ ВАМ РАБОТУ РЕЕСТРА ПО ПРИЧИНЕ ОШИБКИ В КОДЕ, ПИШИТЕ В ПОДДЕРЖКУ" -ForegroundColor Green
    Write-Host ""

    if ($isAssociated) {

        Write-Host "Ассоциация: " -NoNewline

        Write-Host "ВКЛЮЧЕНА" -ForegroundColor Green

        Write-Host ""

        $answer = Read-Host `
            "Убрать ассоциацию .sls? (Y/N)"


        if ($answer -notmatch "^[Yy]$") {

            Write-Host ""
            Write-Host "Отмена." -ForegroundColor Yellow

            return
        }


        try {

            

            if (Test-Path -LiteralPath $ExtensionKey) {

                Remove-Item `
                    -LiteralPath $ExtensionKey `
                    -Recurse `
                    -Force
            }


            

            if (Test-Path -LiteralPath $ProgIdKey) {

                Remove-Item `
                    -LiteralPath $ProgIdKey `
                    -Recurse `
                    -Force
            }


            $fileExtsKey = `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.sls"


            if (Test-Path -LiteralPath $fileExtsKey) {

                Remove-Item `
                    -LiteralPath $fileExtsKey `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue
            }


            Refresh-Explorer


            Write-Host ""
            Write-Host "Ассоциация .sls удалена!" `
                -ForegroundColor Green
        }
        catch {

            Write-Host ""
            Write-Host "Ошибка удаления:" -ForegroundColor Red

            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    else {

        Write-Host "Ассоциация: " -NoNewline

        Write-Host "ВЫКЛЮЧЕНА" -ForegroundColor Yellow

        Write-Host ""

        $answer = Read-Host `
            "Сделать ассоциацию .sls? (Y/N)"


        if ($answer -notmatch "^[Yy]$") {

            Write-Host ""
            Write-Host "Отмена." -ForegroundColor Yellow

            return
        }

        if (-not (Test-Path -LiteralPath $ScriptPath)) {

            Write-Host ""
            Write-Host "ОШИБКА!" -ForegroundColor Red

            Write-Host ""

            Write-Host "Не найден:"
            Write-Host $ScriptPath -ForegroundColor Yellow

            Write-Host ""

            return
        }


        try {

            New-Item `
                -Path $ProgIdKey `
                -Force `
                | Out-Null


            Set-ItemProperty `
                -Path $ProgIdKey `
                -Name "(default)" `
                -Value "SLS Archive" 

            New-Item `
                -Path $IconKey `
                -Force `
                | Out-Null


            Set-ItemProperty `
                -Path $IconKey `
                -Name "(default)" `
                -Value "shell32.dll,3"


            New-Item `
                -Path $CommandKey `
                -Force `
                | Out-Null


            $command =
                "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" `"%1`""


            Set-ItemProperty `
                -Path $CommandKey `
                -Name "(default)" `
                -Value $command

            New-Item `
                -Path $ExtensionKey `
                -Force `
                | Out-Null


            Set-ItemProperty `
                -Path $ExtensionKey `
                -Name "(default)" `
                -Value $ProgId


            
            
            
            

            $fileExtsKey = `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.sls"


            if (Test-Path -LiteralPath $fileExtsKey) {

                Remove-Item `
                    -LiteralPath $fileExtsKey `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue
            }


            Refresh-Explorer


            Write-Host ""
            Write-Host "Ассоциация .sls создана!" `
                -ForegroundColor Green

            Write-Host ""

            Write-Host "SLS-файлы будут открываться через:"
            Write-Host $ScriptPath -ForegroundColor Green

            Write-Host ""
            Write-Host "Администратор НЕ требуется." `
                -ForegroundColor Cyan
        }
        catch {

            Write-Host ""
            Write-Host "Ошибка создания ассоциации:" `
                -ForegroundColor Red

            Write-Host $_.Exception.Message `
                -ForegroundColor Red
        }
    }


    Write-Host ""

    Read-Host "Нажмите Enter для продолжения"
}


if ($args.Count -gt 0) {

    $inputFile = $args[0]


    if (
        (Test-Path -LiteralPath $inputFile) -and
        ([System.IO.Path]::GetExtension($inputFile) -ieq ".sls")
    ) {

        Clear-Host


        Write-Host "====================================" `
            -ForegroundColor Cyan

        Write-Host "             SLS ARCHIVIZER" `
            -ForegroundColor Cyan

        Write-Host "====================================" `
            -ForegroundColor Cyan

        Write-Host ""


        Extract-SLS -InputFile $inputFile


        Write-Host ""

        Read-Host "Нажмите Enter для выхода"


        exit
    }
}

while ($true) {

    Clear-Host


    $association = Test-SLSAssociation


    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host "             SLS ARCHIVIZER" `
        -ForegroundColor Cyan

    Write-Host "====================================" `
        -ForegroundColor Cyan

    Write-Host ""


    Write-Host "1 - Архивация"
    Write-Host "2 - Деархивация"
    Write-Host "3 - Сделать/Убрать ассоциацию"


    Write-Host "Ассоциация: " -NoNewline


    if ($association) {

        Write-Host "ВКЛЮЧЕНА" -ForegroundColor Green
    }
    else {

        Write-Host "ВЫКЛЮЧЕНА" -ForegroundColor Yellow
    }
    Write-Host "0 - Выход"
    Write-Host ""

    $choice = Read-Host "Введите число"


    switch ($choice) {

        "1" {

            Archive-Folder

            Write-Host ""

            Read-Host "Нажмите Enter для продолжения"
        } 

        "2" {

            Extract-SLS

            Write-Host ""

            Read-Host "Нажмите Enter для продолжения"
        }       

        "3" {

            Register-Association
        }
   

        "0" {

            Write-Host ""

            Write-Host "Выход..." -ForegroundColor Cyan

            exit
        }


        default {

            Write-Host ""

            Write-Host `
                "Неверный выбор. Введите 1, 2, 3 или 0." `
                -ForegroundColor Red

            Start-Sleep -Seconds 1
        }
    }
}
