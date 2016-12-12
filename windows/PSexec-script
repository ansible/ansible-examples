
# Open ports 135 and 445 for system you're going to connect to 

# .\remotely_enable_winrm.ps1 -computerName computer name


Param([string]$computerName)

Function enableWinRM {
	$result = winrm id -r:$global:compName 2>$null

	Write-Host	
	if ($LastExitCode -eq 0) {
		Write-Host "WinRM already enabled on" $global:compName "..." -ForegroundColor green
	} else {
		Write-Host "Enabling WinRM on" $global:compName "..." -ForegroundColor red
		.\pstools\psexec.exe \\$global:compName -s C:\Windows\system32\winrm.cmd qc -quiet
		if ($LastExitCode -eq 0) {
			.\pstools\psservice.exe \\$global:compName restart WinRM
			$result = winrm id -r:$global:compName 2>$null
			
			if ($LastExitCode -eq 0) {Write-Host 'WinRM successfully enabled!' -ForegroundColor green}
			else {exit 1}
		} 
		else {exit 1}
	}
}

$global:compName = $computerName
enableWinRM
exit 0
