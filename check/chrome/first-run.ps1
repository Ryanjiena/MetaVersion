Set-PSDebug -Trace 2 -Strict
$dir = (Get-Item .).FullName
if (!(Test-Path "$dir\Data\*") -and (Test-Path "$env:LocalAppData\Google\Chrome\User Data")) {
    Write-Host "[Portable Mode]: Copying user data..." -f darkgray
    Copy-Item "$env:LocalAppData\Google\Chrome\User Data\*" "$dir\Data" -Recurse -Force
}