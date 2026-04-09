Import-Module powershell-yaml
$d = [ordered]@{test='123'}
ConvertTo-Yaml $d
