# Learn-Power-Shell
Power shell tips collected by Ender Phan
# Some useful links:
- https://blog.windowsnt.lv/2011/11/15/tracking-user-activity-english/

- https://technet.microsoft.com/en-us/library/cc281945(v=sql.105).aspx

- https://technet.microsoft.com/et-ee/scriptcenter/dd742419.aspx

- It's a part of the AD module which is a part of RSAT (Remote Server Administration Tools). microsoft.com/en-us/download/details.aspx?id=7887 

- http://powershelltutorial.net/

- https://ss64.com/ps/ ( live with it )

- https://technet.microsoft.com/en-us/scriptcenter/ ( just a blog about Powershell Scripting )
# Some useful books for rookies and masters:

Beginners:

- learn-windows-powershell-3-in-a-month-of-lunches-don-jones-jeffrey-hicks

- PG_PowerShell_XWIPSCRE01_0

# Some useful tips:

- To check AMD:

	`$env:Processor_Architecture`


- Get Service by its variable

	`Get-Service | Where-Object {$_.Name -eq "VSS"}`
	
 	+ Name: is the name of colum 
 	+ VSS: is the name of service
 
- Display by specific column

	`Get-Service | Where-Object {$_.Name -eq "VSS"} | select Status`


- Outfile

	`Get-Service | Where-Object {$_.Status -eq "running"} | Format-list | Out-File .\outhere.txt`

- Responding property variable

	`Get-Process | where {$_.Responding -eq "true"}`

- Operator 

	`Get-Service | Where-Object {($_.Status -eq "running") -and ($_.Name -eq "WSearch")}`

- Whatif command

	`Get-Process notepad |Stop-process -whatif`

- Get-EventLog

	`Get-EventLog -LogName Application -Newest 10`

- Get-help

	`get-help get-process`

- Tracking variable

	`($PSVersionTable).psversion`

from:

Name                           Value                                                                                                                   
----                           -----                                                                                                                   
PSVersion                      4.0                                                                                                                     
WSManStackVersion              3.0                                                                                                                     
SerializationVersion           1.1.0.1                                                                                                                 
CLRVersion                     4.0.30319.42000                                                                                                         
BuildVersion                   6.3.9600.16406                                                                                                          
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0}                                                                                                    
PSRemotingProtocolVersion      2.2 


- List Variables

	`dir variable:`

- Get-Alias

	`Get-Alias`

- Really detail stuffs

	`Get-Process notepad| Format-List * | more`

- Format Table and its property

	`Get-Process | Format-Table -Property Name, Starttime`

	+ Name and starttime are column name ( property )


- if interested in the column ( property ) which contains starttime

	`Get-Process | Where-Object{$_.Starttime}| Format-Table -Property Name, Starttime`

	`* means if Startiime -eq true
	{
		write-host Name, Starttime
	}`

# Alias

- Diffences between process and function to get its alias

	`Get-Alias history`

	`Get-Alias -Definition Where-Object`
	
- Get specific alias

	`Get-alias [?]`

	*[?] exactly ? will be listed
# Services

- To see the services are able to pause or continue

	`Get-Service| ? {$_.CanPauseAndContinue}`

- Get commands about SERVICE

	`Get-Command -Noun service`

![Alt text](/image/get-command-none-service.PNG?raw=true "None service")




- To set the service status

	`Set-Service -Name LanmanServer -Status Paused ( requires administrator mode )`
	
- Get properties of Service

	`Get-Service | Get-Member`


   TypeName: System.ServiceProcess.ServiceController

![Alt text](/image/get-command-none-service.PNG?raw=true "get-member")

# Processes

- To start/stop processes
	
	`Start-Process -FilePath notepad -WindowStyle Maximized`
	
- Kill processes
	
	`Get-Process notepad | kill -WhatIf`
	
# Invoke

- List history using "h"


- Using invoke to remote command thru history ID

	`Invoke-History 2`

![Alt text](/image/help.PNG?raw=true "history")

	
# Event logs

- See the available logs 

	`Get-eventlog -list`
	
- Newest log of Application log

	`Get-EventLog -LogName Application -Newest 5`
	
- Get the applications logs which its message contains a word "WmiApRpl"

	`Get-EventLog -LogName Application | ? {$_.Message -match "WmiApRpl"}`
	
- Differences between -match and property's values

	`1, Get-EventLog -LogName Application -Message "WmiApRpl"` : it doesn't allow
	
	`2, Get-EventLog -LogName Application -InstanceId "1001"` : it does allow
	
	Case 2 is allowed because the value "1001" is matched entirely in the property InstanceId
	
- Select category with Select

	`Get-EventLog -LogName Application -Newest 5| select Source`
	
	
	==> it means whith we should use -match to find the containing word in the property.
		in case if we want to short the command that makes sure the word are contained entirelly in property 
	
# BIOS

- Some:

	`Get-WmiObject -class win32_bios`

	`Alias: gwmi win32_bios`
	
# Some methods

- Maximum value:

	`($array | Measure-Object -Maximum ).Maximum`

	!!!!NB:

		Just use Select to select the property. If we want to get exactly the value of that property. Just use dot (.) to print its value

- Convert out-put to String

	`$getEvent =  Get-EventLog -LogName Application -Newest 19|?{($_.Source -match "SSH") -and  ($_.Message -match "user")} |fl -Property Message |out-string `

	* Use Out-string to convert

- Split, In order to split the output we have to convert it to string variable. 

	`$getEvent.Split(":")`



# Active Directory

	`[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()`

	- [System.DirectoryServices.ActiveDirectory.Domain] --> class identifier 
	- GetCurrentDomain() --> method

Link : 
https://blogs.technet.microsoft.com/heyscriptingguy/2006/11/09/how-can-i-use-windows-powershell-to-get-a-list-of-all-my-computers/

https://technet.microsoft.com/en-us/library/ff730967.aspx


LDAP Scan Map:

http://www.computerperformance.co.uk/Logon/LDAP_attributes_active_directory.htm

Bloodhound
https://blog.cobaltstrike.com/2016/12/14/my-first-go-with-bloodhound/
