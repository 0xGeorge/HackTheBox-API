$APIToken = ""
# No modifications required below here
$UserAgent = "0xGeorgePSWrapper/1.0"
$APIUri = "https://www.hackthebox.eu/api"

function Get-Machines {
    <#
    .SYNOPSIS
    Get a list of all machines & information around each machine
    
    .DESCRIPTION
    Retrieves a list of machines & metadata and prints to screen or stores in a variable

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $json instead

    .EXAMPLE
    PS C:\> Get-Machines

    .EXAMPLE 
    PS C:\> Get-Machines -NoOutput

    .INPUTS
        
    .OUTPUTS
    System.Array

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Switch]$NoOutput
    )

    # Get the data from API
    try {
        $req = Invoke-WebRequest -Uri $APIUri/machines/get/all?api_token=$APIToken -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch machine details. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    if ($NoOutput -eq $false) {
        return $json
    }
    else {
        Set-Variable -Name json -Value $json -Scope Global
    }
}
function Get-MachinesOwned {
    <#
    .SYNOPSIS
    Get a list of machines where user or root has been owned
    
    .DESCRIPTION
    Retrieves a list of machine id and owned status and prints to screen or stores in a variable

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $json2 instead

    .EXAMPLE
    PS C:\> Get-MachinesOwned
    
    .EXAMPLE
    PS C:\> Get-MachinesOwned -NoOutput

    .INPUTS
        
    .OUTPUTS
    System.Array

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Switch]$NoOutput
    )

    # Retrieve data from API
    try {
        $req = Invoke-WebRequest -Uri $APIUri/machines/owns?api_token=$APIToken -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Produce an error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch owned machines. Received unexpected status code: $StatusCode"
        return
    }
    # Parse data and store
    else {   
        $json2 = $req.Content | ConvertFrom-Json      
    }
    # Produce an output
    if ($NoOutput -eq $false) {
        return $json2
    }
    else {
        Set-Variable -Name json2 -Value $json2 -Scope Global
    }
}
function Get-MachineDetails {
    <#
    .SYNOPSIS
    Get a specific / a list of machine(s)
    
    .DESCRIPTION
    Retrieves a specific / a list of machine(s) and prints to screen or stores in a variable $Machine (if single result)

    .PARAMETER MachineName
    Name of machine

    .PARAMETER MachineIP
    IP of machine

    .PARAMETER MachineID
    ID of machine

    .PARAMETER OS
    Operating System of machine

    .PARAMETER Status
    Machines status, accepted values are: All, Active, Retired. Default value if not passed is "All"

    .PARAMETER Owned
    Only shows machines which have a user or root own

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $Machine instead

    .EXAMPLE
    PS C:\> Get-MachineDetails -MachineName MultiMaster

    .EXAMPLE
    PS C:\> Get-MachineDetails -MachineIP 10.10.10.179

    .EXAMPLE
    PS C:\> Get-MachineDetails -MachineID 232

    .EXAMPLE
    PS C:\> Get-MachineDetails -OS Windows -Status Active -Owned

    .INPUTS
        
    .OUTPUTS
    System.Object

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding(DefaultParameterSetName='MachineName')]
    param (
    [Parameter(Mandatory=$true, ParameterSetName="MachineName")]
    [String]$MachineName,
    [Parameter(Mandatory=$true, ParameterSetName="MachineIP")]
    [String]$MachineIP,
    [Parameter(Mandatory=$true, ParameterSetName="MachineID")]
    [Int]$MachineID,
    [Parameter(Mandatory=$true, ParameterSetName="OS")]
    [ValidateSet('Windows','Linux','Other')]
    [String]$OS,
    [Parameter(Mandatory=$false, ParameterSetName="OS")]
    [ValidateSet('All','Active','Retired')]
    [String]$Status = "All",
    [Parameter(Mandatory=$false, ParameterSetName="OS")]
    [Switch]$Owned,
    [Parameter(Mandatory=$false)]
    [Switch]$NoOutput
    )

    # Gather machine data
    Get-Machines -NoOutput

    # Get owned machine data
    Get-MachinesOwned -NoOutput

    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        # Validate input
        if ($MachineName -notmatch '^\w+$') {
            Write-Error "Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        # Loop through machines and find match
        foreach ($Machine in $json) {
            if ($Machine.name -eq $MachineName) {
                    # Append own information to machine object
                    if ($json2.id.Contains($Machine.id)) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                    }
                    else {
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $false
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $false
                    }
                # Produce an output
                if ($NoOutput -eq $false) {
                    return $Machine
                }
                else {
                    Set-Variable -Name Machine -Value $Machine -Scope Global
                    return
                }
            }
        }
        # Produce an error if can't find machine
        if ($Machine) {
            Write-Error "Could not find machine!"
        }
    }
    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        # Validate input
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Error "Enter a valid IPv4 address!"
            return
        }
        # Loop through machine data and find a match
        foreach ($Machine in $json) {
            if ($Machine.ip -eq $MachineIP) {
                    # Append own data
                    if ($json2.id.Contains($Machine.id)) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                    }
                    else {
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $false
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $false
                    }
                # Produce an output
                if ($NoOutput -eq $false) {
                    return $Machine
                }
                else {
                    Set-Variable -Name Machine -Value $Machine -Scope Global
                    return
                }
            }
        }
        # Produce an error if can't find machine
        if ($Machine) {
            Write-Error "Could not find machine!"
        }
    }
    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        # Validate input
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Error "Invalid Machine ID. Must be no larger than 3 digits!"
            return
        }
        # Loop through machines
        foreach ($Machine in $json) {
            if ($Machine.id -eq $MachineID) {
                    # Append own data
                    if ($json2.id.Contains($Machine.id)) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                    }
                    else {
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $false
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $false
                    }
                # Produce an output
                if ($NoOutput -eq $false) {
                    return $Machine
                }
                else {
                    Set-Variable -Name Machine -Value $Machine -Scope Global
                    return
                }
            }
        }
        # Produce an erorr if can't find machine
        if ($Machine) {
            Write-Error "Could not find machine!"
        }
    }
    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "OS") {
        # Loop through machines
        foreach ($Machine in $json) {
            # Match OS
            if ($Machine.os -eq $OS) {
                # Match Retired status
                if ($Status -eq "Retired" -and $Owned -eq $false) {
                    # Append own data
                    if ($Machine.retired -eq $true) {
                        if ($json2.id.Contains($Machine.id)) {
                            $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                            $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                            $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                        }
                        # If no own data assume not owned
                        else {
                            $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $false
                            $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $false
                        }
                        # Produce an output
                        Write-Output $Machine
                    }
                }
                # Match retired and owned
                if ($Status -eq "Retired" -and $Owned -eq $true) {
                    # Append own data
                    if ($json2.id.Contains($Machine.id) -and $Machine.retired -eq $true) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                        # Produce an output
                        Write-Output $Machine
                    }
                }
                # Match active and owned
                if ($Status -eq "Active" -and $Owned -eq $true) {
                    # Append own data
                    if ($json2.id.Contains($Machine.id) -and $Machine.retired -eq $false) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                        # Produce an output
                        Write-Output $Machine
                    }
                }
                # Match all owned machines
                if ($Status -eq "All" -and $Owned -eq $true) {
                    # Append own data
                    if ($json2.id.Contains($Machine.id)) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                        # Produce an output
                        Write-Output $Machine
                    }
                }
                # Match all unowned machines
                if ($Status -eq "All" -and $Owned -eq $false) {
                    # Append own data (should always hit the else)
                    if ($json2.id.Contains($Machine.id)) {
                        $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                    }
                    else {
                        $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $false
                        $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $false
                    }
                    # Produce an output
                    Write-Output $Machine
                }
                # Match active unowned machines
                if ($Status -eq "Active" -and $Owned -eq $false) {
                    # Filter for inactive machines
                    if ($Machine.retired -eq $false) {
                        # Append own data
                        if ($json2.id.Contains($Machine.id)) {
                            $own = $json2 | Where-Object {$_.id -eq $Machine.id} | Select-Object owned_user,owned_root
                            $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $own.owned_user
                            $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $own.owned_root
                        }
                        else {
                            $Machine | Add-Member -NotePropertyName owned_user -NotePropertyValue $false
                            $Machine | Add-Member -NotePropertyName owned_root -NotePropertyValue $false
                        }
                        # Produce an output
                        Write-Output $Machine
                    }                    
                }               
            }
        }
    } 
}
function Submit-Flag {
    <#
    .SYNOPSIS
    Submit user or root flag
    
    .DESCRIPTION
    Submits a user or root flag own through HTB API

    .PARAMETER MachineName
    Name of machine

    .PARAMETER MachineIP
    IP of machine

    .PARAMETER MachineID
    ID of machine

    .PARAMETER Flag
    Value from user.txt or root.txt

    .PARAMETER Difficulty
    Difficuly rating to submit. Integer between 1-10

    .EXAMPLE
    PS C:\> Submit-Flag -MachineName MultiMaster -Flag asadijihcushciuhdsiu... -Difficulty 8
   
    .EXAMPLE
    PS C:\> Submit-Flag -MachineIP 10.10.10.179 -Flag asadijihcushciuhdsiu... -Difficulty 8

    .INPUTS
    System.String
    System.Int
        
    .OUTPUTS
    System.String

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding(DefaultParameterSetName='MachineName')]
    param (
    [Parameter(Mandatory=$true, ParameterSetName="MachineName")]
    [String]$MachineName,
    [Parameter(Mandatory=$true, ParameterSetName="MachineIP")]
    [String]$MachineIP,
    [Parameter(Mandatory=$true, ParameterSetName="MachineID")]
    [Int]$MachineID,
    [Parameter(Mandatory=$true)]
    [String]$Flag,    
    [Parameter(Mandatory=$true)]
    [Int]$Difficulty
    )

    # Check if difficulty is between 1-10
    if ($Difficulty -notmatch '^([1-9]|10)$') {
        Write-Error "Invalid Difficulty. Provide a value between 1-10!"
        return
    }

    # Check flag is in acceptable format
    if ($Flag -notmatch '^\w{32}$') {
        Write-Error "Invalid Flag format. Expecting 32 character alphanumeric string!"
        return
    }

    # Ammend Difficulty
    $Difficulty = $Difficulty*10

    # Check which parameter was passed and verify format before retrieving machine details
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        if ($MachineName -notmatch '^(\d|\w)+$') {
            Write-Error "Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        Get-MachineDetails -MachineName $MachineName
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Error "Enter a valid IPv4 address!"
            return
        }
        Get-MachineDetails -MachineIP $MachineIP
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Error "Invalid Machine ID. Must be no larger than 3 digits!"
            return
        }
        Get-MachineDetails -MachineID $MachineID
    } 

    # Construct body of request
    $Data = @{id=$Machine.id; difficulty=$Difficulty; flag=$Flag}

    # Post the flag
    try {
        $req = Invoke-WebRequest -Uri $APIUri/machines/own?api_token=$APIToken -Method POST -UserAgent $UserAgent -Body $Data -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Produce error if not 200 status
    if ($StatusCode -ne 200) {
        Write-Error "Could not submit flag. Received unexpected status code: $StatusCode"
        return
    }
    # Parse the data
    else {   
        $json = $req.Content | ConvertFrom-Json
    }
    # Determine if success or not
    if ($json.success -eq 0) {
        Write-Error "Could not submit flag. API Returned: ${json.status}"
    }
    # Produce an output
    else {
        Write-Output "Successfully sumitted flag!"
        Write-Output $json.status
    }
}
function Reset-Machine {
    <#
    .SYNOPSIS
    Reset a machine on HTB
    
    .DESCRIPTION
    Resets a machine from a given name, ID or IP and prints API response to screen

    .PARAMETER MachineName
    Name of machine

    .PARAMETER MachineIP
    IP of machine

    .PARAMETER MachineID
    ID of machine

    .EXAMPLE
    PS C:\> Reset-Machine -MachineName MultiMaster

    .EXAMPLE
    PS C:\> Reset-Machine -MachineIP 10.10.10.179

    .EXAMPLE
    PS C:\> Reset-Machine -MachineID 232

    .INPUTS
        
    .OUTPUTS
    System.Object

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding(DefaultParameterSetName='MachineName')]
    param (
    [Parameter(Mandatory=$true, ParameterSetName="MachineName")]
    [String]$MachineName,
    [Parameter(Mandatory=$true, ParameterSetName="MachineIP")]
    [String]$MachineIP,
    [Parameter(Mandatory=$true, ParameterSetName="MachineID")]
    [Int]$MachineID
    )

    # Check which parameter was passed and verify format before retrieving machine details
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        if ($MachineName -notmatch '^(\d|\w)+$') {
            Write-Error "Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        Get-MachineDetails -MachineName $MachineName -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Error "Enter a valid IPv4 address!"
            return
        }
        Get-MachineDetails -MachineIP $MachineIP -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Error "Invalid Machine ID. Must be no larger than 3 digits!"
            return
        }
        Get-MachineDetails -MachineID $MachineID -NoOutput
    }  

    # Submit request to API
    try {
        $req = Invoke-WebRequest -Uri $APIUri/vm/reset/$MachineID`?api_token=$APIToken -UserAgent $UserAgent -UseBasicParsing -Method POST
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not reset machine. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json
}
function Expand-Machine {
    <#
    .SYNOPSIS
    Extend a machine on HTB
    
    .DESCRIPTION
    Extends a machine from a given name, ID or IP and prints API response to screen

    .PARAMETER MachineName
    Name of machine

    .PARAMETER MachineIP
    IP of machine

    .PARAMETER MachineID
    ID of machine

    .EXAMPLE
    PS C:\> Expand-Machine -MachineName MultiMaster

    .EXAMPLE
    PS C:\> Expand-Machine -MachineIP 10.10.10.179

    .EXAMPLE
    PS C:\> Expand-Machine -MachineID 232

    .INPUTS
        
    .OUTPUTS
    System.Object

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding(DefaultParameterSetName='MachineName')]
    param (
    [Parameter(Mandatory=$true, ParameterSetName="MachineName")]
    [String]$MachineName,
    [Parameter(Mandatory=$true, ParameterSetName="MachineIP")]
    [String]$MachineIP,
    [Parameter(Mandatory=$true, ParameterSetName="MachineID")]
    [Int]$MachineID
    )

    # Check which parameter was passed and verify format before retrieving machine details
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        if ($MachineName -notmatch '^(\d|\w)+$') {
            Write-Error "Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        Get-MachineDetails -MachineName $MachineName -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Error "Enter a valid IPv4 address!"
            return
        }
        Get-MachineDetails -MachineIP $MachineIP -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Error "Invalid Machine ID. Must be no larger than 3 digits!"
            return
        }
        Get-MachineDetails -MachineID $MachineID -NoOutput
    } 

    # Submit request to API
    try {
        $req = Invoke-WebRequest -Uri $APIUri/vm/vip/extend/$MachineID`?api_token=$APIToken -UserAgent $UserAgent -UseBasicParsing -Method POST
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not extend machine. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json
}
function Start-Machine {
    <#
    .SYNOPSIS
    Start a machine on HTB
    
    .DESCRIPTION
    Starts a machine from a given name, ID or IP and prints API response to screen

    .PARAMETER MachineName
    Name of machine

    .PARAMETER MachineIP
    IP of machine

    .PARAMETER MachineID
    ID of machine

    .EXAMPLE
    PS C:\> Start-Machine -MachineName MultiMaster

    .EXAMPLE
    PS C:\> Start-Machine -MachineIP 10.10.10.179

    .EXAMPLE
    PS C:\> Start-Machine -MachineID 232

    .INPUTS
        
    .OUTPUTS
    System.Object

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding(DefaultParameterSetName='MachineName')]
    param (
    [Parameter(Mandatory=$true, ParameterSetName="MachineName")]
    [String]$MachineName,
    [Parameter(Mandatory=$true, ParameterSetName="MachineIP")]
    [String]$MachineIP,
    [Parameter(Mandatory=$true, ParameterSetName="MachineID")]
    [Int]$MachineID
    )

    # Check which parameter was passed and verify format before retrieving machine details
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        if ($MachineName -notmatch '^(\d|\w)+$') {
            Write-Error "Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        Get-MachineDetails -MachineName $MachineName -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Error "Enter a valid IPv4 address!"
            return
        }
        Get-MachineDetails -MachineIP $MachineIP -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Error "Invalid Machine ID. Must be no larger than 3 digits!"
            return
        }
        Get-MachineDetails -MachineID $MachineID -NoOutput
    }

    # Submit request to API
    try {
        $req = Invoke-WebRequest -Uri $APIUri/vm/vip/assign/$MachineID`?api_token=$APIToken -UserAgent $UserAgent -UseBasicParsing -Method POST
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not start machine. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json
}
function Stop-Machine {
    <#
    .SYNOPSIS
    Stop a machine on HTB
    
    .DESCRIPTION
    Stops a machine from a given name, ID or IP and prints API response to screen

    .PARAMETER MachineName
    Name of machine

    .PARAMETER MachineIP
    IP of machine

    .PARAMETER MachineID
    ID of machine

    .EXAMPLE
    PS C:\> Stop-Machine -MachineName MultiMaster

    .EXAMPLE
    PS C:\> Stop-Machine -MachineIP 10.10.10.179

    .EXAMPLE
    PS C:\> Stop-Machine -MachineID 232

    .INPUTS
        
    .OUTPUTS
    System.Object

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding(DefaultParameterSetName='MachineName')]
    param (
    [Parameter(Mandatory=$true, ParameterSetName="MachineName")]
    [String]$MachineName,
    [Parameter(Mandatory=$true, ParameterSetName="MachineIP")]
    [String]$MachineIP,
    [Parameter(Mandatory=$true, ParameterSetName="MachineID")]
    [Int]$MachineID
    )

    # Check which parameter was passed and verify format before retrieving machine details
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        if ($MachineName -notmatch '^(\d|\w)+$') {
            Write-Error "Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        Get-MachineDetails -MachineName $MachineName -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Error "Enter a valid IPv4 address!"
            return
        }
        Get-MachineDetails -MachineIP $MachineIP -NoOutput
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Error "Invalid Machine ID. Must be no larger than 3 digits!"
            return
        }
        Get-MachineDetails -MachineID $MachineID -NoOutput
    }

    # Submit request to API
    try {
        $req = Invoke-WebRequest -Uri $APIUri/vm/vip/remove/$MachineID`?api_token=$APIToken -UserAgent $UserAgent -UseBasicParsing -Method POST
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not stop machine. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json
}
########################################################################################## V4 API BELOW HERE ##########################################################################################
function Request-HTBJWT {
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)]
    [String]$Email,
    [Parameter(Mandatory=$false)]
    [Security.SecureString]$Password
    )
    
    # Check if Password was passed with a value, if not prompt for password and convert to plaintext
    $emptypwd = [string]::IsNullOrWhiteSpace($Password)
    if ($emptypwd -eq $true) {
        $Password = Read-Host 'Please enter your password' -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }

    try {
        $body = "{`"email`":`"$Email`",`"password`":`"$PlainPassword`",`"remember`":`"true`"}"
        $req = Invoke-WebRequest -Uri $APIUri/v4/login -Body $body -UserAgent $UserAgent -UseBasicParsing -ContentType 'application/json;charset=utf-8' -Method POST 
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not get token. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    $token = $json.message.access_token

    # Convert Token to Encrypted Secure String and store
    $securestring = ConvertTo-SecureString $token -AsPlainText -Force 
    $encryptedstring = ConvertFrom-SecureString -SecureString $securestring
    $encryptedstring | Export-Clixml -Path $PSScriptRoot\htbjwt.xml
    Write-Output "Stored encrypted token at $PSScriptRoot\htbjwt.xml"
}
function Read-HTBJWT {

    if ((Test-Path -Path $PSScriptRoot\htbjwt.xml -PathType Leaf) -eq $false) {
        Write-Output "Could not find token at $PSScriptRoot\htbjwt.xml. Requesting new token..."
        Request-HTBJWT
    }
    else {
        Write-Verbose "Found existing token!"
    }

    $test = Test-Path $PSScriptRoot\htbjwt.xml -OlderThan (Get-Date).AddDays(-29)

    if ($test -eq $true) {
        Write-Verbose "Token is older than 29 days. Due to expire soon. Requesting fresh token"
        Request-HTBJWT
    }
    else {
        Write-Verbose "Token is not 29 days old yet"
    }

    if ($token -notmatch '^[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$') {
        Write-Verbose "Token does not appear to be in `$token. Reading token..."
        $encryptedstring = Import-CliXml -Path $PSScriptRoot\htbjwt.xml
        $encryptedstring = ConvertTo-SecureString $encryptedstring
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedstring)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        Set-Variable -Name token -Value $token -Scope Global
    }
    else {
        Write-Verbose "Token stored in `$token"
    }
}
function Get-ProLabProgress {
    Read-HTBJWT
    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/profile/progress/prolab/5833 -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch machine details. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json.profile.prolabs
}
function Test-ConnectionStatus {
    
    Read-HTBJWT
    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/user/connection/status -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch connection status. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json
}
function Get-AssignedMachine {
    Read-HTBJWT
    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/profile/machine/active -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "You do not have an active machine currently. Received status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
    }
    # Produce an output
    return $json
}
function Get-ActiveMachines {
    <#
    .SYNOPSIS
    Get a list of active machines
    
    .DESCRIPTION
    Retrieves a list of active machines and prints to screen or stores in a variable

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $ActiveMachines instead

    .EXAMPLE
    PS C:\> Get-ActiveMachines
    
    .EXAMPLE
    PS C:\> Get-ActiveMachines -NoOutput

    .INPUTS
        
    .OUTPUTS
    System.Array

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Switch]$NoOutput
    )

    Read-HTBJWT

    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/machine/list -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch active machines. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
        $ActiveMachines = $json.info
    }
    # Produce an output
    if ($NoOutput -eq $false) {
        return $ActiveMachines
    }
    else {
        Set-Variable -Name ActiveMachines -Value $ActiveMachines -Scope Global
    }
}
function Get-RetiredMachines {
    <#
    .SYNOPSIS
    Get a list of retired machines
    
    .DESCRIPTION
    Retrieves a list of retired machines and prints to screen or stores in a variable

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $RetiredMachines instead

    .EXAMPLE
    PS C:\> Get-RetiredMachines
    
    .EXAMPLE
    PS C:\> Get-RetiredMachines -NoOutput

    .INPUTS
        
    .OUTPUTS
    System.Array

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Switch]$NoOutput
    )

    Read-HTBJWT

    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/machine/list/retired -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch retired machines. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json
        $RetiredMachines = $json.info  
    }
    # Produce an output
    if ($NoOutput -eq $false) {
        return $RetiredMachines
    }
    else {
        Set-Variable -Name RetiredMachines -Value $RetiredMachines -Scope Global
    }
}
function Get-ActiveChallenges {
    <#
    .SYNOPSIS
    Get a list of active challenges
    
    .DESCRIPTION
    Retrieves a list of active challenges and prints to screen or stores in a variable

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $ActiveChallenges instead

    .EXAMPLE
    PS C:\> Get-ActiveChallenges
    
    .EXAMPLE
    PS C:\> Get-ActiveChallenges -NoOutput

    .INPUTS
        
    .OUTPUTS
    System.Array

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Switch]$NoOutput
    )

    Read-HTBJWT

    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/challenge/list -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch active challenges. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json  
        $ActiveChallenges = $json.challenges
    }
    # Produce an output
    if ($NoOutput -eq $false) {
        return $ActiveChallenges
    }
    else {
        Set-Variable -Name ActiveChallenges -Value $ActiveChallenges -Scope Global
    }
}
function Get-RetiredChallenges {
    <#
    .SYNOPSIS
    Get a list of retired challenges
    
    .DESCRIPTION
    Retrieves a list of retired challenges and prints to screen or stores in a variable

    .PARAMETER NoOutput
    Does not print to screen. Sets to a var called $RetiredChallenges instead

    .EXAMPLE
    PS C:\> Get-RetiredChallenges
    
    .EXAMPLE
    PS C:\> Get-RetiredChallenges -NoOutput

    .INPUTS
        
    .OUTPUTS
    System.Array

    .NOTES

    .LINK 
    https://github.com/0xGeorge/HackTheBox-API
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Switch]$NoOutput
    )

    Read-HTBJWT

    try {
        $req = Invoke-WebRequest -Uri $APIUri/v4/challenge/list/retired -Headers @{Authorization = "Bearer $token"} -UserAgent $UserAgent -UseBasicParsing
        $StatusCode = $req.StatusCode
    }
    catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
    }
    # Error if unexpected response
    if ($StatusCode -ne 200) {
        Write-Error "Could not fetch retired challenges. Received unexpected status code: $StatusCode"
        return
    }
    # Parse and store data
    else {   
        $json = $req.Content | ConvertFrom-Json
        $RetiredChallenges = $json.challenges
    }
    # Produce an output
    if ($NoOutput -eq $false) {
        return $RetiredChallenges
    }
    else {
        Set-Variable -Name RetiredChallenges -Value $RetiredChallenges -Scope Global
    }
}