$sourcemodDir = "D:\sourcemod\addons\sourcemod"
$spcompPath = "$sourcemodDir\scripting\spcomp.exe"
$pluginsPath = "$sourcemodDir\plugins"
$defaultArguments = "-i 'D:\Github\robogithub\include' -i 'D:\sourcemod-custom-includes' -O2 -v2"

$spFiles = Get-ChildItem -Path "$PSScriptRoot" -Filter "*.sp"

foreach ($spFile in $spFiles) {
    if ($spFile.FullName -like "*joke*" -or
        $spFile.FullName -like "*test*" -or
        $spFile.FullName -like "*dont_compile*" -or
        $spFile.FullName -like "*don_compile*" -or
        $spFile.FullName -like "*changeteam.sp" -or
        $spFile.FullName -like "*enablemvm.sp"){
        continue;
    }

if ($spFile.Name -like "berobot_*.sp") {
    $outputPath = $spFile.Directory.FullName + "\compiled\mm_handlers\" + $spFile.BaseName + ".smx"
} elseif ($spFile.Name -like "*_ability.sp") {
    # Check for specific prefixes here
    if ($spFile.Name -like "free_*.sp" -or
        $spFile.Name -like "paid_*.sp" -or
        $spFile.Name -like "boss_*.sp") {
        $outputPath = $spFile.Directory.FullName + "\compiled\mm_robots\robot_abilities\" + $spFile.BaseName + ".smx"
    } else {
        $outputPath = $spFile.Directory.FullName + "\compiled\mm_robots\" + $spFile.BaseName + ".smx"
    }
} else {
    $outputPath = $spFile.Directory.FullName + "\compiled\mm_attributes\" + $spFile.BaseName + ".smx"
}
    $arguments = "$($spFile.FullName) -o=$outputPath $defaultArguments"
    $command = "$spcompPath $arguments"

    Write-Host $command;
    Invoke-Expression $command;
    if ($LASTEXITCODE -ne 0){
        exit;
    }
    Write-Host "";

    Copy-Item -Path $outputPath -Destination $pluginsPath
}
