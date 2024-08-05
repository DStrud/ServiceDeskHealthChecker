# Function to get system uptime
function Get-Uptime {
    param(
        [string]$ComputerName
    )
    try {
        $os = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
        $lastBootUpTime = $os.LastBootUpTime
        $uptime = (Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($lastBootUpTime))
        
        # Check if uptime is greater than 2 days
        if ($uptime.Days -gt 2) {
            # Display text in red if uptime is greater than 2 days
            Write-Host ("Uptime: {0:dd} Days {0:hh} Hrs" -f $uptime) -ForegroundColor Red
        } else {
            # Display text in default color otherwise
            Write-Host ("Uptime: {0:dd} Days {0:hh} Hrs" -f $uptime)
        }
    } catch {
        Write-Host "Error retrieving uptime: $($_.Exception.Message)" -ForegroundColor Red
    }
}

 
# Function to get current logged-in user
function Get-LoggedInUser {
    param(
        [string]$ComputerName
    )
    try {
        $sessions = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName
        $loggedInUser = $sessions.UserName
        Write-Output ("Logged-in User: {0}" -f $loggedInUser)
    } catch {
        Write-Output "Error retrieving logged-in user: $($_.Exception.Message)"
    }
}
 
# Function to get C drive space
function Get-DriveSpace {
    param(
        [string]$ComputerName
    )
    try {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" -ComputerName $ComputerName
        $freeSpaceGB = [math]::round($disk.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::round($disk.Size / 1GB, 2)
        
        # Determine the color based on free space
        if ($freeSpaceGB -lt 5) {
            # Red color for less than 5 GB
            Write-Host ("C: Drive Space: {0} GB free of {1} GB total" -f $freeSpaceGB, $totalSpaceGB) -ForegroundColor Red
        } elseif ($freeSpaceGB -lt 10) {
            # Yellow color for less than 10 GB
            Write-Host ("C: Drive Space: {0} GB free of {1} GB total" -f $freeSpaceGB, $totalSpaceGB) -ForegroundColor Yellow
        } else {
            # Default color for 10 GB or more
            Write-Host ("C: Drive Space: {0} GB free of {1} GB total" -f $freeSpaceGB, $totalSpaceGB)
        }
    } catch {
        Write-Host "Error retrieving C: drive space: $($_.Exception.Message)" -ForegroundColor Red
    }
}
 
# Function to get network information
function Get-NetworkInfo {
    param(
        [string]$ComputerName
    )
    try {
        $networkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" -ComputerName $ComputerName
        Write-Output "Network Information:"
        $networkAdapters | ForEach-Object {
            Write-Output ("  Network Adapter: {0}" -f $_.Description)
            Write-Output ("    IP Address: {0}" -f ($_.IPAddress -join ", "))
            Write-Output ("    MAC Address: {0}" -f $_.MACAddress)
        }
    } catch {
        Write-Output "Error retrieving network information: $($_.Exception.Message)"
    }
}
 
# Function to get operating system details
function Get-OSDetails {
    param(
        [string]$ComputerName
    )
    try {
        $os = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
        Write-Output ("Operating System: {0}" -f $os.Caption)
        Write-Output ("  Version: {0}" -f $os.Version)
        #Write-Output ("  Architecture: {0}" -f $os.OSArchitecture)
        #Write-Output ("  Last Boot Time: {0}" -f ([Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)))
    } catch {
        Write-Output "Error retrieving operating system details: $($_.Exception.Message)"
    }
}

# Function to get operating system details
function Get-Temperature {
    param (
        [string]$ComputerName
    )
    try {
        # Get temperature data from the thermal zones
        $t = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ComputerName $ComputerName
        $returntemp = @()
        
        foreach ($temp in $t) {
            #$currentTempKelvin = $temp.CurrentTemperature / 10
            $currentTempCelsius = $currentTempKelvin - 273.15
            #$currentTempFahrenheit = (9/5) * $currentTempCelsius + 32

            $returntemp += "Zone: $($temp.InstanceName) - $currentTempCelsius C"
        }
        
        # Display the temperature information
        if ($returntemp.Count -gt 0) {
            Write-Host "Temperature Readings:" -ForegroundColor Cyan
            $returntemp | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "No temperature data available." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error retrieving temperature data: $($_.Exception.Message)" -ForegroundColor Red
    }
}




# Main loop for checking multiple computers
do {
    # Prompt for the remote computer name
    $RemoteComputer = Read-Host "RXC/IP:"
 
    # Execute the functions and display results
    Write-Output "Checking status of computer: $RemoteComputer"
 
    Write-Output (Get-Uptime -ComputerName $RemoteComputer)
    Write-Output (Get-LoggedInUser -ComputerName $RemoteComputer)
    Write-Output (Get-DriveSpace -ComputerName $RemoteComputer)
    #Write-Output (Get-NetworkInfo -ComputerName $RemoteComputer)
    Write-Output (Get-OSDetails -ComputerName $RemoteComputer)
    Write-Output (Get-Temperature -ComputerName $RemoteComputer)

    # Ask if the user wants to check another computer
    $continue = Read-Host "Do you want to check another computer? (y/n)"
} while ($continue -eq 'y' -or $continue -eq 'Y')

Write-Output "Exiting the script."
