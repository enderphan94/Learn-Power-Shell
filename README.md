# Learn-Power-Shell
Power shell tips by Ender Phan
# Some useful links:
- https://blog.windowsnt.lv/2011/11/15/tracking-user-activity-english/

- https://technet.microsoft.com/en-us/library/cc281945(v=sql.105).aspx

- https://technet.microsoft.com/et-ee/scriptcenter/dd742419.aspx

- It's a part of the AD module which is a part of RSAT (Remote Server Administration Tools). microsoft.com/en-us/download/details.aspx?id=7887 

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

