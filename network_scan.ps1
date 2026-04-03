# Network Scanner Script with User Detection
# Author: Network Scanner v1.0

# Function to get current timestamp
function Get-TimeStamp {
    return Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
}

# Request subnet from user
Write-Host "=== Network Scanner with User Detection ===" -ForegroundColor Green
Write-Host ""
$subnet = Read-Host "Enter subnet (example: 192.168.1 or 10.0.0)"

# Validate input
if (-not $subnet -or $subnet -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Host "Error: Invalid subnet format. Use format: 192.168.1" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Choose output format
Write-Host ""
Write-Host "Choose output format:"
Write-Host "1 - TXT file (text format)"
Write-Host "2 - CSV file (Excel table)"
$choice = Read-Host "Enter 1 or 2"

# Create filename with timestamp
$timestamp = Get-TimeStamp
$outputPath = ""

switch ($choice) {
    "1" { 
        $outputPath = "network_scan_$timestamp.txt"
        $format = "TXT"
    }
    "2" { 
        $outputPath = "network_scan_$timestamp.csv"
        $format = "CSV"
    }
    default { 
        $outputPath = "network_scan_$timestamp.txt"
        $format = "TXT"
        Write-Host "Default format selected: TXT" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Starting network scan of $subnet.0/24..." -ForegroundColor Yellow
Write-Host "Results will be saved to: $outputPath" -ForegroundColor Cyan
Write-Host ""

# Array to store results
$results = @()

# Header for TXT file
if ($format -eq "TXT") {
    $header = @"
=== Network Scan Results ===
Subnet: $subnet.0/24
Scan Date: $(Get-Date -Format "dd.MM.yyyy HH:mm:ss")
Found devices:

IP Address        Computer Name                     User                              Display Name
=======================================================================================================
"@
    $header | Out-File -FilePath $outputPath -Encoding UTF8
}

# Device counter
$deviceCount = 0

# Scan subnet
1..254 | ForEach-Object {
    $currentIP = $_
    $ip = "$subnet.$currentIP"
    
    # Show progress
    Write-Progress -Activity "Network Scanning" -Status "Checking $ip" -PercentComplete (($currentIP / 254) * 100)
    
    if (Test-Connection $ip -Count 1 -Quiet) {
        try {
            $hostname = [System.Net.Dns]::GetHostByAddress($ip).HostName
            
            # Check logged in user
            $user = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $hostname -ErrorAction SilentlyContinue | Select-Object UserName
            
            # Get DisplayName from AD
            $displayName = ""
            $userLogin = ""
            
            if ($user -and $user.UserName) {
                $userLogin = $user.UserName
                # Extract username without domain
                $username = $user.UserName.Split('\')[-1]
                try {
                    # Get DisplayName from AD
                    $adUser = Get-ADUser -Identity $username -Properties DisplayName, Description -ErrorAction SilentlyContinue
                    if ($adUser) {
                        $displayName = if ($adUser.DisplayName) { $adUser.DisplayName } else { $adUser.Description }
                    }
                } catch {
                    # Ignore AD lookup errors
                }
            } else {
                $userLogin = "No user logged in"
            }
            
            # Create result object
            $deviceInfo = [PSCustomObject]@{
                IP = $ip
                Hostname = $hostname
                User = $userLogin
                DisplayName = if ($displayName) { $displayName } else { "Not found" }
            }
            
            $results += $deviceInfo
            $deviceCount++
            
            # Console output
            Write-Host "Found: $ip - $hostname - $userLogin - $displayName" -ForegroundColor Green
            
        } catch {
            # Device found but not accessible via WMI
            $deviceInfo = [PSCustomObject]@{
                IP = $ip
                Hostname = "Not accessible"
                User = "Not accessible"
                DisplayName = "Not accessible"
            }
            
            $results += $deviceInfo
            $deviceCount++
            
            Write-Host "Found: $ip - Device not accessible for queries" -ForegroundColor Yellow
        }
    }
}

# Complete progress bar
Write-Progress -Activity "Network Scanning" -Completed

Write-Host ""
Write-Host "Scan completed. Found devices: $deviceCount" -ForegroundColor Green

# Save results
if ($results.Count -gt 0) {
    if ($format -eq "CSV") {
        # Save to CSV with header
        $results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        
        # Add scan information to beginning of CSV file
        $csvContent = Get-Content $outputPath
        $header = @(
            "# Network Scan Results",
            "# Subnet: $subnet.0/24", 
            "# Date: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')",
            "# Found devices: $deviceCount",
            ""
        )
        ($header + $csvContent) | Set-Content $outputPath -Encoding UTF8
        
    } else {
        # Add results to TXT file
        foreach ($device in $results) {
            $line = "{0,-17} {1,-33} {2,-33} {3}" -f $device.IP, $device.Hostname, $device.User, $device.DisplayName
            $line | Add-Content -Path $outputPath -Encoding UTF8
        }
        
        # Add summary
        "" | Add-Content -Path $outputPath -Encoding UTF8
        "=======================================================================================================" | Add-Content -Path $outputPath -Encoding UTF8
        "Total devices found: $deviceCount" | Add-Content -Path $outputPath -Encoding UTF8
        "Scan completed: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" | Add-Content -Path $outputPath -Encoding UTF8
    }
    
    Write-Host "Results saved to file: $outputPath" -ForegroundColor Cyan
    
    # Offer to open file
    $openFile = Read-Host "Would you like to open the results file? (y/n)"
    if ($openFile -eq "y" -or $openFile -eq "Y" -or $openFile -eq "yes") {
        try {
            Invoke-Item $outputPath
        } catch {
            Write-Host "Could not open file automatically. Find file: $outputPath" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "No active devices found in subnet $subnet.0/24" -ForegroundColor Red
}

Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green
Read-Host "Press Enter to exit"