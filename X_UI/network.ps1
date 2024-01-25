function Convert-SubnetMaskToPrefixLength {
    param (
        [string]$subnetMask
    )
    $octets = $subnetMask.Split('.')
    $prefixLength = 0
    foreach ($octet in $octets) {
        $prefixLength += [Convert]::ToString([int]$octet, 2).ToCharArray() | 
        Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
    }
    return $prefixLength
}

# Example usage
$subnetMask = "255.255.254.0"
$prefixLength = Convert-SubnetMaskToPrefixLength -subnetMask $subnetMask
Write-Host "Prefix Length: $prefixLength"


###########################################################################################################


function Clear-NetAdapter {
    param (
        [string]$Adapter
    )
    $adapterName = Get-NetAdapter | Where-Object { $_.Name -like $Adapter }
    if (-not $adapterName.Name) {
        Write-Host "No Adapter by this name: $Adapter"
        return;
    }
    else {
        try {
            $gateway = Get-NetRoute -InterfaceAlias $adapterName.Name -DestinationPrefix 0.0.0.0/0 2>$null
            $gateway | Remove-NetRoute 2>$null -Confirm:$false           
        }
        catch {
            Write-Host "No Gateway" -ForegroundColor "Yellow"
        }
        finally {
            $ipConfig = Get-NetIPAddress -InterfaceAlias $adapterName.Name
            if ($ipConfig) {
                $ipConfig | Remove-NetIPAddress -Confirm:$false  
            }
            Restart-NetAdapter -InterfaceAlias $adapterName.Name  
            Set-NetIPInterface -InterfaceAlias $adapterName.Name -Dhcp Enabled  
            Set-DnsClientServerAddress -InterfaceAlias $adapterName.Name -ResetServerAddresses 
        }
    }
}

###########################################################################################################


function Set-NetAdapter {
    param (
        [string]$AdapterName,[string]$IPAddress,
        [string]$SubnetMask,[string]$Gateway,
        [string]$DNSPrimary,[string]$DNSSecondary
    )
    try {
        Clear-NetAdapter -Adapter $AdapterName -Wait
    }
    catch {
       Write-Host $_ 
    }
    finally {
        try {
            netsh interface ipv4 set address name=$AdapterName source=static address=$IPAddress mask=$subnetMask 
            if ($DNSPrimary) {
                netsh interface ipv4 set dns name=$AdapterName static $DNSPrimary
            }
            if ($DNSSecondary) {
                netsh interface ipv4 add dns name=$AdapterName $DNSSecondary index=2  
            }
            if ($Gateway) {
                netsh interface ipv4 set address name=$AdapterName source=static address=$IPAddress mask=$subnetMask gateway=$Gateway
            }        
        }
        catch {
            Write-Host $_ 
        }
    }  
}

#########################################################################################################
#For Main use 

function IsAdpaterConfigured {
    param (
        [string]$interface
    )
    $ipConfig = Get-NetIPAddress -InterfaceAlias $interface
    $hasStaticIP = $ipConfig | Where-Object { $_.PrefixOrigin -eq "Manual" }
    if ($hasStaticIP) {
        $result = $true
    } 
    else {
        $result = $false
    }   
    return $result
}



$functionResult = FunctionName

if ($functionResult) {
    Write-Host "Static"
}
else {
    Write-Host "DHCP"
}


#########################################################################################################



