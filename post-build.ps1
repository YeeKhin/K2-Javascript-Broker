# Post-Build script to deploy the minified JS to the DB

# Set active path to script-location:
$path = $MyInvocation.MyCommand.Path
if (!$path) {$path = $psISE.CurrentFile.Fullpath}
if ( $path) {$path = Split-Path $path -Parent}
Set-Location $path

# Start JavaScript broker host
# Get the K2 installation directory
$k2Path = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\SourceCode\blackpearl\blackpearl Core" -Name "InstallDir")."InstallDir"
$jsHost = "$($k2Path)SourceCode.JavaScript.BrokerHost\SourceCode.JavaScript.BrokerHost.exe"
$jsHostProcess = Get-Process | Where-Object {$_.ProcessName -eq "SourceCode.JavaScript.BrokerHost"}
if ($null -eq $jsHostProcess ) {Start-Process $jsHost}

# Get config values from package.json
$packageJson = Get-Content -Raw -Path "$($path)\package.json" | ConvertFrom-Json
$environmentId = $packageJson.environmentId
$scriptName = $packageJson.name

# Setup temporary JavaScript host and get endpoint
$endpoint = "http://localhost:5000"
$baseUrl = "$($endpoint)/api/v1/environments/$($environmentId)/scripts"
$requestUrl = "$($baseUrl)/$($scriptName)"
$inFile = "$($path)\dist\index.js"

# Post minified JS to JS Broker Host endpoint
# if we don't get a response, then it is likley that host isn't running yet, so we will suppress the error and try again
# Error: Invoke-RestMethod : Unable to connect to the remote server
do
{
    $ErrorActionPreference = "SilentlyContinue"; #This will hide errors
    $response = (Invoke-RestMethod -uri $requestUrl -Method Post -InFile $inFile -ContentType "application/javascript") 2> $null
    $ErrorActionPreference = "Continue"; #Turning errors back on
    $id = $response.id
    if($null -eq $id){Write-Output "Waiting for JavaScript Broker Host to start"}
}
until($null -ne $id)
$endpointServiceKey = "$($baseUrl)/$($id)"

# Contruct the output endpoint and copy to clipboard
Write-Output "The following endpoint has been copied to your clipboard."
Write-Output "Please paste it as your JavaScript Broker Endpoint Service Key."
Write-Output $endpointServiceKey
Write-Output ""
Set-Clipboard $endpointServiceKey