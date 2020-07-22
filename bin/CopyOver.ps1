Param([Parameter(Mandatory)][ValidateSet('Push','Pull')][String]$Method)

[System.Xml.XmlDocument]$CopyConfig = Get-Content $PSScriptRoot\CopyOver.xml;
[System.Boolean]$Found = $false;
foreach($Machine in $CopyConfig.CopyOver.Machines.Machine)
{
  if($Machine.ComputerName -eq $env:COMPUTERNAME){[System.Xml.XmlElement]$MachineXml = $Machine;$Found = $true;}
}
if(!$Found){throw "Error in config";}

New-Item $MachineXml.LogPath -Force | Out-Null;

switch($Method)
{
  "Push"{[String]$Command = "put -neweronly $($MachineXml.Item)";}
  "Pull"{[String]$Command = "get -neweronly $($MachineXml.Item)";}
}

& "$($MachineXml.WinSCPVariables.Path)" `
  /log="$($MachineXml.LogPath)" /ini=nul `
  /command `
    "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
    "lcd $($MachineXml.Local)" `
    "cd $($MachineXml.Remote)" `
    "$($Command) -nopreservetime" `
    "exit"

[int16]$winscpResult = $LastExitCode;
if ($winscpResult -eq 0)
{
  Write-Host "Success";
}
else
{
  Write-Host "Error";
}

exit $winscpResult
