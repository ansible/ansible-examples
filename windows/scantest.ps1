$MyObject = @()

Get-ChildItem "C:\Windows\" -Filter *.log | Foreach-Object {

  $filename = $_.BaseName

  $MyObject += [pscustomobject]@{ 'FileName' = $filename; 'content' = get-content $_.FullName | select-string -Pattern '.' | where {$_ -notmatch '^#.*' -and $_ -notmatch '^\s*#.*' } | Select-Object LineNumber,Line }

}

echo $MyObject

