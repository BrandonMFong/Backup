<#
.Synopsis
  A way to keep my notes in sync
#>

[System.Xml.XmlDocument]$CopyConfig = Get-Content $PSScriptRoot\Backup.xml;
[System.Boolean]$Found = $false;
foreach($Machine in $CopyConfig.App.Machines.Machine)
{
  if($Machine.ComputerName -eq $env:COMPUTERNAME){[System.Xml.XmlElement]$MachineXml = $Machine;$Found = $true;}
}
if(!$Found){throw "Error in config";}

New-Item $MachineXml.LogPath -Force | Out-Null; # Clearing log file
[String]$RemotePath = $MachineXml.Remote + "/" + $MachineXml.Item; # Getting file path with linux syntax 

# how to set it so that if delete on remote, it will delete locally
# Sync command
[String]$PutCommand = "put -neweronly $($MachineXml.Item) -nopreservetime";
[String]$RemoveCommand = "rm $($RemotePath)/*";

# Execute the command on WinSCP
& "$($MachineXml.WinSCPVariables.Path)" `
  /log="$($MachineXml.LogPath)" /ini=nul `
  /command `
    "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
    "lcd $($MachineXml.Local)" `
    "cd $($MachineXml.Remote)" `
    "$($RemoveCommand)" `
    "$($PutCommand)" `
    "exit"

[int16]$winscpResult = $LastExitCode;
if ($winscpResult -eq 0){Write-Host "Success";}
else{Write-Host "Error";}

exit $winscpResult;
