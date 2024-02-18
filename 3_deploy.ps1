$sourcemodDir = "D:\sourcemod\addons\sourcemod"
$spcompPath = "$sourcemodDir\scripting\spcomp64.exe"
$pluginsPath = "$sourcemodDir\plugins"
$defaultArguments = "-i 'D:\Github\robogithub\include' -i 'D:\sourcemod-custom-includes' -O2 -v2"

# Specify the root folder explicitly
$rootFolder = $PSScriptRoot
$spFiles = Get-ChildItem -Path $rootFolder -Filter "*.sp" -File

foreach ($spFile in $spFiles) {
    # Your filtering conditions go here...
    if ($spFile.Name -like "*joke*" -or
        $spFile.Name -like "*test*" -or
        $spFile.Name -like "*dont_compile*" -or
        $spFile.Name -like "*don_compile*" -or
        $spFile.Name -eq "changeteam.sp" -or
        $spFile.Name -eq "enablemvm.sp") {
        continue
    }

    $outputPath = ""

    if ($spFile.Name -like "berobot_*.sp") {
        $outputPath = Join-Path -Path $rootFolder -ChildPath "compiled\mm_handlers\$($spFile.BaseName).smx"
    } elseif ($spFile.Name -like "ability_*.sp") {
        $folderPath = Join-Path -Path $rootFolder -ChildPath "compiled\mm_robots\robot_abilities"
        $outputPath = Join-Path -Path $folderPath -ChildPath $spFile.Name
    } elseif ($spFile.Name -like "free_*.sp" -or $spFile.Name -like "paid_*.sp" -or $spFile.Name -like "boss_*.sp") {
        $folderPath = Join-Path -Path $rootFolder -ChildPath "compiled\mm_robots"
        $outputPath = Join-Path -Path $folderPath -ChildPath $spFile.Name
    } elseif ($spFile.Name -like "mm_*.sp") {
        $folderPath = Join-Path -Path $rootFolder -ChildPath "compiled\mm_attributes"
        $outputPath = Join-Path -Path $folderPath -ChildPath $spFile.Name
    } else {
        # If the file does not match any specific condition, skip it
        continue
    }

    # Create the necessary folders if they don't exist
    if (-not (Test-Path -Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force
    }

    $arguments = "$($spFile.FullName) -o=$outputPath $defaultArguments"
    $command = "$spcompPath $arguments"

    Write-Host $command
    Invoke-Expression $command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Compilation failed for $($spFile.FullName)"
        exit
    }
    Write-Host ""

    # Check if the output file exists before attempting to copy
    if (Test-Path -Path $outputPath) {
        # Copy the compiled file to the plugins directory
        Copy-Item -Path $outputPath -Destination $pluginsPath
    } else {
        Write-Host "Output file $($outputPath) does not exist. Skipping copying to plugins directory."
    }
}
