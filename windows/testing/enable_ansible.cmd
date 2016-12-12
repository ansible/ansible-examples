#Comment
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1', 'C:\ConfigureRemotingForAnsible.ps1')"
powershell -ExecutionPolicy Bypass -Command "& 'C:\ConfigureRemotingForAnsible.ps1'"
