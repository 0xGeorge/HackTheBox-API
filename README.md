# HackTheBox-API

- Unofficial PowerShell wrapper for HackTheBox API

Currently functionality:
- Get a list of all machines
- Get information about a specific machine
- Filter machines based on OS, owned status and active/retired
- Submit flags (Doesn't support Pro Labs or ReleaseArena)

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
Get-Command -Module HTBAPI -Syntax

Get-MachineDetails -MachineName <string> 

Get-MachineDetails -MachineIP <string> 

Get-MachineDetails -MachineID <int> 

Get-MachineDetails -OS <string> [-Status <string> All,Active,Retired] [-Owned] 

Get-Machines [-NoOutput] 

Get-MachinesOwned [-NoOutput] 

Submit-Flag -MachineName <string> -Flag <string> -Difficulty <int> 

Submit-Flag -MachineIP <string> -Flag <string> -Difficulty <int> 

Submit-Flag -MachineID <int> -Flag <string> -Difficulty <int> 
```