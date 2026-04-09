Import-Module powershell-yaml

$path = "d:\Dev\glazewm-konfig\docs\examples\config.yaml"
$tempPath = "d:\Dev\glazewm-konfig\test_out.yaml"

$yaml = Get-Content $path -Raw | ConvertFrom-Yaml
$yamlOut = ConvertTo-Yaml $yaml
Set-Content -Path $tempPath -Value $yamlOut -Encoding UTF8

$yaml2 = Get-Content $tempPath -Raw | ConvertFrom-Yaml
Write-Host "Success loading saved YAML."
