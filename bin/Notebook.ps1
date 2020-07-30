Param([ValidateSet('Push','Pull')][String]$Method)

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
[String]$Command = $null;
foreach($Item in $MachineXml.Items.Item)
{
  switch($Item.cmd)
  {
    # "Push"{[String]$Command = "put -neweronly $($MachineXml.Item) -nopreservetime";}
    # "Pull"{[String]$Command = "get -neweronly $($MachineXml.Item) -nopreservetime";}
    "PushPull"
    {
      switch($Method)
      {
        "Push"{[String]$Command = "put -neweronly $($Item.InnerText) -nopreservetime";}
        "Pull"{[String]$Command = "get -neweronly $($Item.InnerText) -nopreservetime";}
      }
    }
    "Delete"
    {
      [String]$Command = "rm $($Item.InnerText)";
    }
  }

  # Execute the command on WinSCP
  if(![string]::IsNullOrEmpty($Command))
  {
    & "$($MachineXml.WinSCPVariables.Path)" `
      /log="$($MachineXml.LogPath)" /ini=nul `
      /command `
        "open sftp://$($MachineXml.WinSCPVariables.Username):$($MachineXml.WinSCPVariables.Password)@$($MachineXml.WinSCPVariables.IP)/ -hostkey=`"`"$($MachineXml.WinSCPVariables.SSHKey)`"`" -rawsettings Cipher=`"`"aes,chacha20,3des,WARN,des,blowfish,arcfour`"`"" `
        "lcd $($MachineXml.Local)" `
        "cd $($MachineXml.Remote)" `
        "$($Command)" `
        "exit"

      # Delete locally 
      if($Item.cmd -eq "Delete")
      {
        [String]$i = $Item.InnerText;
        Remove-Item $($MachineXml.Local + "\" + $i.Replace("/","\")) -Verbose -Force -Recurse;
      }
  }
}

[int16]$winscpResult = $LastExitCode;
if ($winscpResult -eq 0){Write-Host "Success";}
else{Write-Host "Error";}

exit $winscpResult;
