function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String[]]
		$VMName,

		[parameter(Mandatory = $true)]
		[System.String]
		$PseudoKey
	)

	
	$returnValue = @{
		VMName    = $VMName
		PseudoKey = $PseudoKey
	}

	$returnValue	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String[]]
		$VMName,

		[parameter(Mandatory = $true)]
		[System.String]
		$PseudoKey
	)

    $Count = $VMName.Count

    while($Count -gt 0)
    {
        Write-Verbose 'Waiting for IP Address for VMs'

        $Count = $VMName.Count

        foreach($Name in $VMName)
        {
            $Adapter = Get-VMNetworkAdapter -VMName $VMName

            if ($Adapter.IPAddresses.Count -ge 2)
            {
                $Count--  
            }
            else
            {
                Write-Verbose "IP Address for VM $Name not ready"
            }
        }

        Start-Sleep -Seconds 2
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String[]]
		$VMName,

		[parameter(Mandatory = $true)]
		[System.String]
		$PseudoKey
	)

    $Count = $VMName.Count

    foreach($Name in $VMName)
    {
        $Adapter = Get-VMNetworkAdapter -VMName $VMName

        if ($Adapter.IPAddresses.Count -ge 2)
        {
            $Count--  
        }
    }

    if ($Count -eq 0)
    {
        return $true
    }
    else 
    {
        return $false
    }
}



