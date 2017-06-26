#Dev by Ender Loc Phan
<#Requirements:

Import-Module ActiveDirectory
#>
<#Usage 1.0
 - Suppy the objectClass (Eg: user, group, person...)

 - Just Enumerate Distinguished name

 .\adTracking.ps1 -dna           # Enumerate Distinguished name and print it to console
 .\adTracking.ps1 -dna -addToReport   # Write Distinguished name to text file
 .\adTracking.ps1 -dna -addToReport -amount 100   # Write Distinguished name to text file with specific amout of data
 .\adTracking.ps1 -dna -amount 100       # Print given amount of Distinguished name to console

 - Get All attributes

 .\adTracking.ps1               # Enumerate  all supplied LDAP Attributes and print it to console
 .\adTracking.ps1 -addToReport  # Write all data to CSV file
 .\adTracking.ps1 -addToReport -amount 100 # Write data to CSV file with given amount of data
 .\adTracking.ps1 -amount 100       # Print given amount of data to console   
#>    

<# Update 1.1
- Added the trusted domain method
- Fixed Account expires function
- Fixed PasswordLS
- change parameters to optional methods

Usage 1.1: Just flow the options given by the tool
#>

$activeMo = Import-Module ActiveDirectory -ErrorAction Stop

Write-Verbose -Message  "This tool is running under PowerShell version $($PSVersionTable.PSVersion.Major)" -Verbose
write-host 
write-host " 1. Run on current domain "
write-host " 2. Run on trusted domains "
write-host 
$type =  Read-Host -Prompt "Option "

if ($type -eq 1) 
{
  # Get the Current Domain data  
  $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
}
elseif($type -eq 2) 
{
    write-host
    write-host " 1. Enter trusted domain manually "
    write-host " 2. Get all trusted domain automatically"
    write-host
    $trust = Read-Host -Prompt "Option "
    if($trust -eq 1){
        
        $trustDN = Read-Host -Prompt "Domain "
        write-host
        $TrustedDomain = $trustDN
    }
    elseif($trust -eq 2){
    
        $trustedD = Get-ADTrust -Filter * | select Name | Out-String
        $trustedD             
        $trustDN = Read-Host -Prompt "Domain "
        write-host
        $TrustedDomain = $trustDN            
    }

    $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$TrustedDomain)
    Try 
    {
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
        Write-Verbose -Message "Connect to $Domain successfully" -Verbose
    }
        Catch [exception] {
        $Host.UI.WriteErrorLine("ERROR: $($_.Exception.Message)")
        Exit
    }
}
else
{
    Write-Verbose -Message  "Option is not valid" -Verbose
}

$objectClass =  Read-Host -Prompt "objectClass "
$ADSearch = New-Object System.DirectoryServices.DirectorySearcher
#new empty ad search, search engine someth we can send queries to find out

$ADSearch.SearchRoot ="LDAP://$Domain"
#where we wanna look in LDAP is Domain, because we don't wanna search from root
#root is: $objDomain = New-Object System.DirectoryServices.DirectoryEntry

$ADSearch.SearchScope = "subtree"
$ADSearch.PageSize = 100

$ADSearch.Filter = "(objectClass=$objectClass)"
#where objectClass attribute are -eq to user
#Atribute to search for: ObjectClass
# value of attribute : user
#exp: $ADSearch.Filter = "(Name=Ender)"

#values in array are atttibutes of LDAP
$properies =@("distinguishedName",
"sAMAccountName",
"mail",
"lastLogonTimeStamp",
"pwdLastSet",
"badpwdcount",
"accountExpires",
"userAccountControl")
foreach($pro in $properies)
{
    $ADSearch.PropertiesToLoad.add($pro)| out-null
    #the name of property of the object, search will load the name in an array #properties
}
$ProgressBar = $True
$userObjects = $ADSearch.FindAll()
$userCount =  $userObjects.Count
$result = @()
$count = 0

# Creating csv file
$invalidChars = [io.path]::GetInvalidFileNameChars()
$dateTimeFile = ((Get-Date -Format s).ToString() -replace "[$invalidChars]","-")
$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$outFile = $($PSScriptRoot)+"\$($Domain)-Report-$($dateTimeFile).csv"
$outFileTxt = $($PSScriptRoot)+"\Report-$($dateTimeFile).txt"
$outFileHTM = $($PSScriptRoot)+"\Report-$($dateTimeFile).htm"
$Delimiter = ","
$NeverExpires = 9223372036854775807
$userValue = @("512",
"514",
"544",
"546",
"66048",
"66050",
"66080",
"66082",
"262656",
"262658",
"262688",
"262690",
"328192",
"328194",
"328224",
"328226")
$head = @’

<style>

body { background-color:#dddddd;

       font-family:Tahoma;

       font-size:12pt; }

td, th { border:1px solid black;

         border-collapse:collapse; }

th { color:white;

     background-color:black; }

table, tr, td, th { padding: 2px; margin: 0px }

table { margin-left:50px; }

</style>

‘@
# Supplied Attributes
Function tracking
{
    $dn =  $user.Properties.Item("distinguishedName")[0]    
    $global:sam = $user.Properties.Item("sAMAccountName")[0]
    $logon = $user.Properties.Item("lastLogonTimeStamp")[0]
    $mail =$user.Properties.Item("mail")[0]
    $passwordLS = $user.Properties.Item("pwdLastSet")[0]
    $passwordC = $user.Properties.Item("badpwdcount")[0]
    $accountEx = $user.Properties.Item("accountExpires")[0]
    $accountDis= $user.Properties.Item("userAccountControl")[0]
    $global:exportedToCSV  = $false
    $global:exportedToTxt = $false

    #last Logon
    if($logon.Count -eq 0)
    {
        $lastLogon = "Never logon"
    }
    else
    {
        $lastLogon = [DateTime]$logon[0]
    }
   
    #password last set
    if($passwordLS -eq 0)
    {         
         $value = "No password last set"
    }
    else
    {
         $value = [DateTime]::FromFileTime($passwordLS)
         if($value -eq $("1/1/1601 01:00:00" | Get-Date)){
                $value = "No password last set"    
         }
    }    
 
    #Account expires   
    if($accountEx -eq $NeverExpires)
    {
        $convertAccountEx = "Not Expired"
    }
    else
    {
        #$convertDate = [datetime]$accountEx
        $convertAccountEx = "Expired"
    }

    #Email
    if([String]::IsNullOrEmpty($mail)){
        
        $email = "N/A"
    }
    else{
        $email =$mail
    }

    #PasswordCount
    if([String]::IsNullOrEmpty($passwordC)){

        $passwordCStatus = "N/A"
    }
    else{

        $passwordCStatus = $passwordC   
    }

    #UserInfor
    if($accountDis -eq 512)
    {
        $accountDisStatus = "User is disabled"
    }
    else
    {
        $accountDisStatus = "User ready for logon"
    }  
    $obj = New-object -TypeName psobject
    $obj | Add-Member -MemberType NoteProperty -Name "Distinguished Name" -Value $dn
    $obj | Add-Member -MemberType NoteProperty -Name "Sam account" -Value $sam
    $obj | Add-Member -MemberType NoteProperty -Name "Email" -Value $email
    $obj | Add-Member -MemberType NoteProperty -Name "Password last changed" -Value $value
    $obj | Add-Member -MemberType NoteProperty -Name "Bad password count" -Value $passwordCStatus
    $obj | Add-Member -MemberType NoteProperty -Name "Last Logon " -Value $lastLogon
    $obj | Add-Member -MemberType NoteProperty -Name "Account Expires" -Value $convertAccountEx
    $obj | Add-Member -MemberType NoteProperty -Name "Account Status" -Value $accountDisStatus    
    <#
    $props=@{"Distinguished Name" =$dn
             "Sam account"=$sam
             "Pass word last changed"=$value
             "Last Logon"=$lastLogon
             "Account Expires"=$convertAccountEx
             "Account Status"=$accountDisStatus
    }
    #>
    if($exportCheck -eq $true)
    {<#
        if($valueType -eq $true)
        {#>
            
            $global:exportedToCSV = $true
            $obj | Export-Csv -Path "$outFile" -NoTypeInformation -append -Delimiter $Delimiter
        <#}
        elseif($valueType -eq $false)
        {
         #$props|ConvertTo-HTML -head $head -PreContent “<h1>Hardware Inventory for SERVER2</h1>” |  Out-File -FilePath "C:\Users\p998wph\Documents\Ender\test2.htm"
            
             $props
        } #>    
    }
    else
    {
        $obj 
    }

    
    
}
#Main run here
$cls = cls
function main{
    # distinguished Name method
    $arrayDN = @()
    if($dna -eq $true)
    {
        if($amountCheck -eq $true)
        {
            Write-Host
            Write-Verbose -Message  "Please be patient whilst the script retrieves all $amount distinguished names..." -Verbose        
        
            foreach ($user  in $userObjects)
            {
                if($count -lt $amount)
                {
                    $sam = $user.Properties.Item("sAMAccountName")[0]
                    $dn =  $user.Properties.Item("distinguishedName")[0]
                               
                    if($exportCheck -eq $true){
                        $global:exportedToTxt = $true
                        $dn | Out-File "$outFileTxt" -Append
                    }
                    elseif($exportCheck -eq $false){
                        $dn
                        #$arrayDN += $dn
                    }                 
                    $count++    
                    $TotalUsersProcessed++   
                
                }
                If ($ProgressBar) 
                {
                    Write-Progress -Activity "Processing $($amount) Users" -Status ("Count: 
                    $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$amount)*100)
                }
            }
            #$arrayDN
        }    
        elseif($amountCheck -eq $false)
        {
            Write-Host
            Write-Verbose -Message  "Please be patient whilst the script retrieves all $userCount distinguished names..." -Verbose
            foreach ($user  in $userObjects)
            {
                $sam = $user.Properties.Item("sAMAccountName")[0]
                $dn =  $user.Properties.Item("distinguishedName")[0]
                if($exportCheck -eq $true)
                {
                        $global:exportedToTxt = $true
                        $dn | Out-File "$outFileTxt" -Append
                }
                elseif($exportCheck -eq $false)
                {
                        $dn
                        #$arrayDN += $dn
                } 
                $TotalUsersProcessed++
                If ($ProgressBar) 
                {
                    Write-Progress -Activity "Processing $($userCount) Users" -Status ("Count: 
                    $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$userCount)*100)
                }
            }        
            #$arrayDN
        }
    }
    ## Finished distinguished Name method

    elseif($amountCheck -eq $true)
    {
        Write-Host
        Write-Verbose -Message  "Please be patient whilst the script retrieves all $amount distinguished names..." -Verbose
        foreach ($user  in $userObjects)
        {
            if($count -lt $amount)
            {
                tracking
                $TotalUsersProcessed++
                $count++
                If ($ProgressBar) 
                {                
                    Write-Progress -Activity "Processing $($amount) Users" -Status ("Count: 
                    $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$amount)*100)              
                }
            
            }
        }
    }
    elseif($amountCheck -eq $false)
    {
        Write-Host
        Write-Verbose -Message  "Please be patient whilst the script retrieves all $userCount distinguished names..." -Verbose
        foreach ($user  in $userObjects)
        {    
            tracking
            $TotalUsersProcessed++
            If ($ProgressBar) 
            {
                Write-Progress -Activity "Processing $($userCount) Users" -Status ("Count: 
                $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$userCount)*100)
            }
        }
    }
}

#optional choices
function optional{

    write-host
    write-host " 1. Get distinguished name "
    write-host " 2. Get all supplied attributes"
    write-host
    $methods = Read-Host -Prompt "Option "
    if($methods -eq 1)
    {
        $dna = $true
    }
    elseif ($methods -eq 2)
    {
        $dna = $false
    }else
    {
        Write-Verbose -Message  "Option is not valid" -Verbose
        exit
    }
    #Amount
    $amount = Read-Host -Prompt "Amount of data (Enter to get all data)"
    if($amount -eq ""){        
        $amountCheck = $false
    }
    else
    {        
        $amountCheck = $true
    }    
    #Export
    $export = Read-Host -Prompt "Do you want to export the data? (y/n)"
    if(($export -eq "y") -or ($export -eq ""))
    {
        $exportCheck = $true
    }
    elseif($export -eq "n")
    {
         $exportCheck = $false
    }
    else
    {
        Write-Verbose -Message  "Option is not valid" -Verbose
        exit
    }
    <#
    write-host
    write-host " 1. CSV "
    write-host " 2. HTML"
    write-host

    $fileType = Read-Host -Prompt "File type "

    if($fileType -eq 1)
    {
        $valueType = $true
    }
    elseif($fileType -eq 2)
    {
        $valueType = $false
    }
    #>

    main
}
#Options
if($type -eq 1)
{  
    optional  
}
elseif($type -eq 2)
{
    optional   
}
else{

    Write-Verbose -Message  "Option is not valid" -Verbose
    exit
}
if($exportedToCSV -eq $true){
        Write-Host
        Write-Host "Data has been exported to $outFile" -foregroundcolor "magenta"
}
if($exportedToTxt -eq $true){
        Write-Host
        Write-Host "Data has been exported to $outFileTxt" -foregroundcolor "magenta"
}

#Finish
Write-Host
Write-Verbose -Message  "Script Finished!!" -Verbose
