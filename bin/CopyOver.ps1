Param([Parameter(Mandatory)][ValidateSet('Push','Pull')][String]$Method)

[System.Xml.XmlDocument]$CopyConfig = Get-Content $PSScriptRoot\CopyOver.xml;
New-Item $MachineXml.LogPath -Force | Out-Null;

[System.Boolean]$Found = $false;
foreach($Machine in $CopyConfig.CopyOver.Machines.Machine)
{
  if($Machine.ComputerName -eq $env:COMPUTERNAME){[System.Xml.XmlElement]$MachineXml = $Machine;$Found = $true;}
}
if(!$Found){throw "Error in config";}

# Check if need pull
# I am assuming the NOTEBOOK folder is a sub dir from both the local and remote configured dir
& "$($MachineXml.WinSCPVariables.Path)" `
  /log="$($MachineXml.LogPath)" /ini=nul `
  /command `
    "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
    "lcd $($MachineXml.Local)\$($MachineXml.Item)\bin" `
    "cd $($MachineXml.Remote)/$($MachineXml.Item)/bin" `
    "get Time -nopreservetime" `
    "exit"

[String]$TimeFilePath = "$($MachineXml.Remote)\$($MachineXml.Item)\bin\Time";
[DateTime]$RemoteTimeStamp = Get-Content $TimeFilePath;
[DateTime]$LocalTimeStamp = $MachineXml.LastFetch;
if($RemoteTimeStamp -gt $LocalTimeStamp)
{
  throw "Please pull";
}


# Main method
switch($Method)
{
  # Maybe I can use the time file to flag that I need to pull just like git
  # https://winscp.net/eng/docs/faq_script_modified_files#relative_time_constraint
  "Push"{[String]$Command = "put $($MachineXml.Item)";}
  "Pull"{[String]$Command = "get $($MachineXml.Item)";}
}
& "$($MachineXml.WinSCPVariables.Path)" `
  /log="$($MachineXml.LogPath)" /ini=nul `
  /command `
    "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
    "lcd $($MachineXml.Local)" `
    "cd $($MachineXml.Remote)" `
    "$($Command) -nopreservetime" `
    "exit"

$winscpResult = $LastExitCode
if ($winscpResult -eq 0)
{
  Write-Host "Success"
}
else
{
  Write-Host "Error"
}

exit $winscpResult