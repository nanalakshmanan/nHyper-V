
function New-UnattendFile
{
    param( 
          [string] $ComputerName,
          [string] $IPv4Address,
          [string] $IPv6Address,
          [PSCredential]$AdministratorCredentials
)
       
    # Convert secure string to plaintext to place inside the unattend.xml
    $AdministratorPassword = $AdministratorCredentials.GetNetworkCredential().Password

    [string] $xmlStr =  @"
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <NetworkLocation>Work</NetworkLocation>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
            <Value>$AdministratorPassword</Value>
            <PlainText>true</PlainText>
			    </AdministratorPassword>
		    </UserAccounts>
	    </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>$ComputerName</ComputerName>
        </component>
         <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
                <RunSynchronousCommand>
                    <Order>1</Order>
                    <Path>%SYSTEMDRIVE%\Content\command\unattend.cmd</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>    
"@
                
    $xmlStr += @"            
    <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <Interfaces>
        <Interface wcm:action="add">
          <Ipv4Settings>
            <DhcpEnabled>false</DhcpEnabled>
          </Ipv4Settings>
          <Ipv6Settings>
            <DhcpEnabled>false</DhcpEnabled>
          </Ipv6Settings>
          <Identifier>Ethernet</Identifier>
          <UnicastIpAddresses>
"@
    if ($IPv4Address)
    {
        $xmlStr += @"
            <IpAddress wcm:action="add" wcm:keyValue="1">$IPv4Address</IpAddress>
"@
    }
    if ($IPv6Address)
    {
        $xmlStr += @"
            <IpAddress wcm:action="add" wcm:keyValue="1">$IPv6Address</IpAddress>
"@
    }
            
    $xmlStr += @"
          </UnicastIpAddresses>
"@    
            
    $xmlStr += @"
        </Interface>
      </Interfaces>
    </component>
  </settings>
</unattend>
"@

    $xmlStr
}

configuration nUnattend
{
    [CmdletBinding()]

    param(
        [string]
        $VhdPath,

        [string]
        $ComputerName,

        [PSCredential]
        $AdministratorCredentials,

        [string]
        $IPV4Address,

        [string]
        $IPV6Address,

        [string]
        $UnattendCommand
    )

    Import-DscResource -ModuleName xHyper-V

    $TempFile = [IO.Path]::GetTempFileName()
    $UnattendContents = New-UnattendFile -ComputerName $ComputerName -IPv4Address $IPV4Address -IPv6Address $IPV6Address -AdministratorCredentials $AdministratorCredentials
    $UnattendContents | Out-File -FilePath $TempFile -Encoding ascii

    $FileDirectoryToCopy = @(                            
                            MSFT_xFileDirectory {
                                                    SourcePath      = $TempFile
                                                    DestinationPath = 'Windows\Panther\unattend.xml'
                                                    Ensure          = 'Present'
                                                }
                  )

    $FileDirectoryToCopy += @(
                            MSFT_xFileDirectory {
                                                  SourcePath      = $UnattendCommand
                                                  DestinationPath = 'Content\Command\unattend.cmd'
                                                  Ensure          = 'Present'                                                 
                                              }
                                      )

    xVhdFile "$ComputerName.Unattend.Inject"
    {
            VhdPath       = $VhdPath
            FileDirectory = $FileDirectoryToCopy
            CheckSum      = 'ModifiedDate'
    }
}