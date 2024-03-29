﻿$workingDir = Get-Location
$dirInfo= New-Object -Typename System.IO.DirectoryInfo -ArgumentList ($workingDir)
$projectName= $dirInfo.Name;
$key=$env:nugetKey
$buildDay=[DateTime]::Now.ToString("yyyyMMddHHmmss")
$p="buildDay=$($buildDay)".Trim()
$build="Release"

function RunCommand
{
    $numOfArgs = $args.Length
    for ($i=0; $i -lt $numOfArgs; $i++)
    {
        iex $args[$i]
        if($LASTEXITCODE -eq 0 -or $i -eq 0) {
            Write-Host "$($args[$i]) success"
        }
        else{
            Write-Host "$($args[$i]) failed"
            return 0
        }
    }
    return 1
}

function NugetPack
{
    $numOfArgs = $args.Length
    for ($i=0; $i -lt $numOfArgs; $i++)
    {
        Write-Host "NugetPack $($args[$i])"

        $result = RunCommand "Remove-Item -Recurse -Force .\bin\$($build)\**" `
            "dotnet build .\$($args[$i]).csproj -c $($build)" `
            "nuget pack .\$($args[$i]).nuspec -Symbols -OutputDirectory .\bin\$($build) -p 'id=$($args[$i]);$($p)'"

        if($result) {
            Write-Host "$($args[$i]) success"
        }
        else{
            Write-Host "$($args[$i]) failed"
            return 0
        }
    }
    return 1 
}

function NugetPush
{
    $numOfArgs = $args.Length
    for ($i=0; $i -lt $numOfArgs; $i++)
    {
        Write-Host "NugetPush $($args[$i])"
        
        $files = [System.IO.Directory]::GetFiles(".\bin\$($build)\")
        iex "nuget push $($files[0]) -ApiKey $($key) -Source https://api.nuget.org/v3/index.json"
    }
}

$result = NugetPack $projectName
if($result)
{
    if([string]::IsNullOrEmpty($key))
    {
        Write-Host "Build & pack success"
    }
    else
    {
        Write-Host "enter to push nuget"
        pause
        Write-Host "enter to confirm"
        pause

        NugetPush $projectName
    }
}
else
{
    echo "Build & pack error"
}
pause