# Learn-Power-Shell
Power shell tips collected by Ender Phan
# Some useful links:
- https://blog.windowsnt.lv/2011/11/15/tracking-user-activity-english/

- https://technet.microsoft.com/en-us/library/cc281945(v=sql.105).aspx

- https://technet.microsoft.com/et-ee/scriptcenter/dd742419.aspx

- It's a part of the AD module which is a part of RSAT (Remote Server Administration Tools). microsoft.com/en-us/download/details.aspx?id=7887 

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

CommandType     Name                                               ModuleName                       
-----------     ----                                               ----------                       
Cmdlet          Get-Service                                        Microsoft.PowerShell.Management  

Cmdlet          New-Service                                        Microsoft.PowerShell.Management  

Cmdlet          Restart-Service                                    Microsoft.PowerShell.Management  

Cmdlet          Resume-Service                                     Microsoft.PowerShell.Management  

Cmdlet          Set-Service                                        Microsoft.PowerShell.Management  

Cmdlet          Start-Service                                      Microsoft.PowerShell.Management  

Cmdlet          Stop-Service                                       Microsoft.PowerShell.Management  

Cmdlet          Suspend-Service                                    Microsoft.PowerShell.Management 




- To set the service status

	`Set-Service -Name LanmanServer -Status Paused ( requires administrator mode )`
	
- Get properties of Service

	`Get-Service | Get-Member`


   TypeName: System.ServiceProcess.ServiceController

Name                      MemberType    Definition                                                  
----                      ----------    ----------                                                  
Name                      AliasProperty Name = ServiceName                                          
RequiredServices          AliasProperty RequiredServices = ServicesDependedOn                       
Disposed                  Event         System.EventHandler Disposed(System.Object, System.EventA...
Close                     Method        void Close()                                                
Continue                  Method        void Continue()                                             
CreateObjRef              Method        System.Runtime.Remoting.ObjRef CreateObjRef(type requeste...
Dispose                   Method        void Dispose(), void IDisposable.Dispose()                  
Equals                    Method        bool Equals(System.Object obj)                              
ExecuteCommand            Method        void ExecuteCommand(int command)                            
GetHashCode               Method        int GetHashCode()                                           
GetLifetimeService        Method        System.Object GetLifetimeService()                          
GetType                   Method        type GetType()                                              
InitializeLifetimeService Method        System.Object InitializeLifetimeService()                   
Pause                     Method        void Pause()                                                
Refresh                   Method        void Refresh()                                              
Start                     Method        void Start(), void Start(string[] args)                     
Stop                      Method        void Stop()                                                 
WaitForStatus             Method        void WaitForStatus(System.ServiceProcess.ServiceControlle...
CanPauseAndContinue       Property      bool CanPauseAndContinue {get;}                             
CanShutdown               Property      bool CanShutdown {get;}                                     
CanStop                   Property      bool CanStop {get;}                                         
Container                 Property      System.ComponentModel.IContainer Container {get;}           
DependentServices         Property      System.ServiceProcess.ServiceController[] DependentServic...
DisplayName               Property      string DisplayName {get;set;}                               
MachineName               Property      string MachineName {get;set;}                               
ServiceHandle             Property      System.Runtime.InteropServices.SafeHandle ServiceHandle {...
ServiceName               Property      string ServiceName {get;set;}                               
ServicesDependedOn        Property      System.ServiceProcess.ServiceController[] ServicesDepende...
ServiceType               Property      System.ServiceProcess.ServiceType ServiceType {get;}        
Site                      Property      System.ComponentModel.ISite Site {get;set;}                 
Status                    Property      System.ServiceProcess.ServiceControllerStatus Status {get;} 
ToString                  ScriptMethod  System.Object ToString(); 

# Processes

- To start/stop processes
	
	`Start-Process -FilePath notepad -WindowStyle Maximized`
	
- Kill processes
	
	`Get-Process notepad | kill -WhatIf`
	
# Invoke

- List history using "h"

Id CommandLine                                                                                    
  -- -----------                                                                                    
   1 get-serice                                                                                     
   2 Get-Service                                                                                    
   3 Get-Service | Where-Object {$_.status -eq "running"}                                           
   4 Get-Service | Where-Object {($_.status -eq "running") and  ($_.Name -eq "WSearch")} | Format...
   5 Get-Service | Where-Object {($_.status -eq "running") and  ($_.Name -eq "WSearch")} | Format...
   6 Get-Service | Where-Object {($_.status -eq "running") -and  ($_.Name -eq "WSearch")} | Forma...
   7 Get-EventLog 
	
- Using invoke to remote command thru history ID

	`Invoke-History 2`
