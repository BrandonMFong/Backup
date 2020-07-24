Param([Parameter(Mandatory)][ValidateSet('Push','Pull')][String]$Method)

[System.Xml.XmlDocument]$CopyConfig = Get-Content $PSScriptRoot\Notebook.xml;
[System.Boolean]$Found = $false;
foreach($Machine in $CopyConfig.Notebook.Machines.Machine)
{
  if($Machine.ComputerName -eq $env:COMPUTERNAME){[System.Xml.XmlElement]$MachineXml = $Machine;$Found = $true;}
}
if(!$Found){throw "Error in config";}

New-Item $MachineXml.LogPath -Force | Out-Null; # Clearing log file

# how to set it so that if delete on remote, it will delete locally
# Sync command
switch($Method)
{
  "Push"{[String]$Command = "put -neweronly $($MachineXml.Item) -nopreservetime";}
  "Pull"{[String]$Command = "get -neweronly $($MachineXml.Item) -nopreservetime";}
}
# [String]$Command = "synchronize both -nopreservetime";

& "$($MachineXml.WinSCPVariables.Path)" `
  /log="$($MachineXml.LogPath)" /ini=nul `
  /command `
    "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
    "lcd $($MachineXml.Local)" `
    "cd $($MachineXml.Remote)" `
    "$($Command)" `
    "exit"

[int16]$winscpResult = $LastExitCode;
if ($winscpResult -eq 0){Write-Host "Success";}
else{Write-Host "Error";}

exit $winscpResult
