Param([Parameter(Mandatory)][ValidateSet('Push','Pull')][String]$Method)

[System.Xml.XmlDocument]$CopyConfig = Get-Content $PSScriptRoot\CopyOver.xml;
New-Item $MachineXml.LogPath -Force | Out-Null;

[System.Boolean]$Found = $false;
foreach($Machine in $CopyConfig.CopyOver.Machines.Machine)
{
  if($Machine.ComputerName -eq $env:COMPUTERNAME){[System.Xml.XmlElement]$MachineXml = $Machine;$Found = $true;}
}
if(!$Found){throw "Error in config";}

switch($Method)
{
  # Maybe I can use the time file to flag that I need to pull just like git
  # https://winscp.net/eng/docs/faq_script_modified_files#relative_time_constraint
  "Push"
  {
    # Check if need pull
    # I am assuming the NOTEBOOK folder is a sub dir from both the local and remote configured dir
    # Get time file
    & "$($MachineXml.WinSCPVariables.Path)" `
      /log="$($MachineXml.LogPath)" /ini=nul `
      /command `
        "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
        "lcd $($MachineXml.Local)\$($MachineXml.Item)\bin" `
        "cd $($MachineXml.Remote)/$($MachineXml.Item)/bin" `
        "get Time" `
        "exit"

    [String]$TimeFilePath = "$($MachineXml.Remote)\$($MachineXml.Item)\bin\Time";
    [DateTime]$timestring = Get-Content $TimeFilePath; # Get datetime from time file

    # if the file is null then you don't need to warn for pull
    # this catches the initial state of this workflow
    if(![string]::IsNullOrEmpty($timestring))
    {
      [DateTime]$RemoteTimeStamp = Get-Content $TimeFilePath; # Get datetime from time file
      [DateTime]$LocalTimeStamp = $MachineXml.LastFetch; # Get datetime from config

      # If the remote time file is greater than the timestamp on config, you need to pull
      if($RemoteTimeStamp -gt $LocalTimeStamp)
      {
        # But if I have updated files locally and I pull then I will overwrite those updated files to the old state
        throw "Please pull";
      }
    }
    [String]$Command = "put $($MachineXml.Item)";
  }
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