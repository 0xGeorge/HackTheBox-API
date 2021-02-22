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
        Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
        Write-Host ": Could not fetch machine details. " -NoNewline
        Write-Host "Received unexpected status code: $StatusCode"
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
        Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
        Write-Host ": Could not fetch owned machines. " -NoNewline
        Write-Host "Received unexpected status code: $StatusCode"
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
    Get a list of artifact assembly names from github repo actions
    
    .DESCRIPTION
    Retrieves assembly names and prints to screen

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
    [Switch]$Owned
    )

    # Gather machine data
    Get-Machines -NoOutput

    # Get owned machine data
    Get-MachinesOwned -NoOutput

    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        # Validate input
        if ($MachineName -notmatch '^\w+$') {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Invalid Machine Name. No spaces or special characters allowed!"
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
                return $Machine
            }
        }
        # Produce an error if can't find machine
        if ($Machine) {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Could not find machine!"
        }
    }
    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        # Validate input
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Host "[-] ERROR " -ForegroundColor Red -NoNewline
            Write-Host ": Enter a valid IPv4 address!"
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
                return $Machine
            }
        }
        # Produce an error if can't find machine
        if ($Machine) {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Could not find machine!"
        }
    }
    # Determine ParameterSet used
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        # Validate input
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Invalid Machine ID. Must be no larger than 3 digits!"
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
                return $Machine
            }
        }
        # Produce an erorr if can't find machine
        if ($Machine) {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Could not find machine!"
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
    Get a list of artifact assembly names from github repo actions
    
    .DESCRIPTION
    Retrieves assembly names and prints to screen

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
        Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
        Write-Host ": Invalid Difficulty. Provide a value between 1-10!"
        return
    }

    # Check flag is in acceptable format
    if ($Flag -notmatch '^\w{32}$') {
        Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
        Write-Host ": Invalid Flag format. Expecting 32 character alphanumeric string!"
        return
    }

    # Ammend Difficulty
    $Difficulty = $Difficulty*10

    # Check which parameter was passed and verify format before retrieving machine details
    if ($PSCmdlet.ParameterSetName -eq "MachineName") {
        if ($MachineName -notmatch '^(\d|\w)+$') {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Invalid Machine Name. No spaces or special characters allowed!"
            return
        }
        Get-MachineDetails -MachineName $MachineName
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineIP") {
        if ($MachineIP -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            Write-Host "[-] ERROR " -ForegroundColor Red -NoNewline
            Write-Host ": Enter a valid IPv4 address!"
            return
        }
        Get-MachineDetails -MachineIP $MachineIP
    }
    if ($PSCmdlet.ParameterSetName -eq "MachineID") {
        if ($MachineID -notmatch '^\d{1,3}$') {
            Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
            Write-Host ": Invalid Machine ID. Must be no larger than 3 digits!"
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
        Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
        Write-Host ": Could not submit flag. " -NoNewline
        Write-Host "Received unexpected status code: $StatusCode"
        return
    }
    # Parse the data
    else {   
        $json = $req.Content | ConvertFrom-Json
    }
    # Determine if success or not
    if ($json.success -eq 0) {
        Write-Host "[-] ERROR" -ForegroundColor Red -NoNewline
        Write-Host ": Could not submit flag. " -NoNewline
        Write-Host "API Returned: ${json.status}"
    }
    # Produce an output
    else {
        Write-Host "[+] " -ForegroundColor DarkGreen -NoNewline
        Write-Host "Successfully sumitted flag!"
        # Check what the parameter is
        Write-Host "[+] " -ForegroundColor DarkGreen -NoNewline
        Write-Host $json.status
    }
}