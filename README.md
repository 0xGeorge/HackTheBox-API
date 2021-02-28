# HackTheBox-API

- Unofficial PowerShell wrapper for HackTheBox API

Currently functionality:
- Get a list with details of all machines
- Get information about a specific machine
- Filter machines based on OS, owned status and active/retired
- Submit flags (Doesn't support Pro Labs or ReleaseArena)
- Spawn a machine (VIP Only)
- Reset a machine
- Extend a machine (VIP Only)
- Stop a machine (VIP Only)
- Get a list with details of active challenges
- Get a list with details of retired challenges
- Find which machine you have assigned (VIP Only)
- Find if you are connected to VPN successfully
- Retrieve ProLab progress

Now utilises v4 API which requires the use of a JWT compared to the API key. A command which uses the v4 API will prompt for credentials upon first usage. This will authenticate to HackTheBox website and encrypt it and store on disk (encrypted) under the path where the PowerShell module was loaded. Token renewal occurs every 29 days.

## Pre-requisites
- Retrieve HackTheBox API Key (https://www.hackthebox.eu/home/settings)

## Installation
```ps
PS C:\> git clone https://github.com/0xGeorge/HackTheBox-API.git

# Insert HTB API key into $APIToken on line 1

PS C:\> notepad.exe HackTheBox-API/HTBAPI.psm1

PS C:\> Import-Module HackTheBox-API/HTBAPI.psm1

```
## Usage
```ps 

Expand-Machine -MachineName <string>

Expand-Machine -MachineIP <string>

Expand-Machine -MachineID <int>

Get-ActiveChallenges [-NoOutput]

Get-ActiveMachines [-NoOutput]

Get-AssignedMachine

Get-MachineDetails -MachineName <string> [-NoOutput]

Get-MachineDetails -MachineIP <string> [-NoOutput]

Get-MachineDetails -MachineID <int> [-NoOutput]

Get-MachineDetails -OS <string> [-Status <string>] [-Owned] [-NoOutput]

Get-Machines [-NoOutput]

Get-MachinesOwned [-NoOutput]

Get-ProLabProgress

Get-RetiredChallenges [-NoOutput]

Get-RetiredMachines [-NoOutput]

Read-HTBJWT

Request-HTBJWT [-Email] <string> [[-Password] <securestring>]

Reset-Machine -MachineName <string>

Reset-Machine -MachineIP <string>

Reset-Machine -MachineID <int>

Start-Machine -MachineName <string>

Start-Machine -MachineIP <string>

Start-Machine -MachineID <int>

Stop-Machine -MachineName <string>

Stop-Machine -MachineIP <string>

Stop-Machine -MachineID <int>

Submit-Flag -MachineName <string> -Flag <string> -Difficulty <int>

Submit-Flag -MachineIP <string> -Flag <string> -Difficulty <int>

Submit-Flag -MachineID <int> -Flag <string> -Difficulty <int>

Test-ConnectionStatus
```