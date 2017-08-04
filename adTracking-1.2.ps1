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
    else{
        Write-Verbose -Message  "Unknown entered option" -Verbose
        exit 
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
    exit
}
$objectCategory =  Read-Host -Prompt "objectCategory "
if($objectCategory -eq ""){
    Write-Verbose -Message  "objectCategory can't be null" -Verbose
    exit    
}
$objectClass =  Read-Host -Prompt "objectClass "
if($objectClass -eq ""){

    Write-Verbose -Message  "Objectclass can't be null" -Verbose
    exit    
}
$PDC = $Domain.PdcRoleOwner
$ADSearch = New-Object System.DirectoryServices.DirectorySearcher
#new empty ad search, search engine someth we can send queries to find out
$ADSearch.SearchRoot ="LDAP://$PDC"
#where we wanna look in LDAP is Domain, because we don't wanna search from root
#root is: $objDomain = New-Object System.DirectoryServices.DirectoryEntry
$ADSearch.SearchScope = "subtree"
$ADSearch.PageSize = 100
$ADSearch.Filter = "(&(objectCategory=$objectCategory)(objectClass=$objectClass))"
#where objectClass attribute are -eq to user
#Atribute to search for: ObjectClass
# value of attribute : user
#exp: $ADSearch.Filter = "(Name=Ender)"
$connect = [ADSI] "LDAP://$($Domain)" 
$lockoutDuration = $connect.lockoutDuration.Value
$lockoutThreshold  =$connect.lockoutThreshold
$maxPwdAge =$connect.maxPwdAge.Value
$maxPwdAgeValue =  $connect.ConvertLargeIntegerToInt64($maxPwdAge)
$duraValue = $connect.ConvertLargeIntegerToInt64($lockoutDuration)
#values in array are atttibutes of LDAP
$properies =@("distinguishedName",
"sAMAccountName",
"mail",
"lastLogonTimeStamp",
"pwdLastSet",
"badpwdcount",
"accountExpires",
"userAccountControl",
"modifyTimeStamp",
"lockoutTime"
"badPasswordTime",
"maxPwdAge ",
"Description"
)
foreach($pro in $properies)
{
    $ADSearch.PropertiesToLoad.add($pro)| out-null
    #the name of property of the object, search will load the name in an array #properties
}
$ProgressBar = $True
$userObjects = $ADSearch.FindAll()
$dnarr = New-Object System.Collections.ArrayList
$modiValues = New-object System.Collections.ArrayList
$Delimiter = ","
$userCount =  $userObjects.Count
$result = @()
$count = 0
# Creating csv file
$invalidChars = [io.path]::GetInvalidFileNameChars()
$dateTimeFile = ((Get-Date -Format s).ToString() -replace "[$invalidChars]","-")
$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$outFile = $($PSScriptRoot)+"\$($Domain)-Report-$($dateTimeFile).csv"
$outFileTxt = $($PSScriptRoot)+"\Report-$($dateTimeFile).txt"
$outFileHTML = $($PSScriptRoot)+"\$($Domain)-Report-$($dateTimeFile).html"
$outFileMeg = $($PSScriptRoot)+"\$($Domain)-FinalReport-$($dateTimeFile).csv"
$outFileModi = $($PSScriptRoot)+"\$($Domain)-ReportModi-$($dateTimeFile).csv"

$Searcher = New-Object System.DirectoryServices.DirectorySearcher 
$Searcher.PageSize = 100 
$Searcher.SearchScope = "subtree" 
$Searcher.Filter = "(&(objectCategory=$objectCategory)(objectClass=$objectClass))"
$Searcher.PropertiesToLoad.Add("distinguishedName")|Out-Null
$Searcher.PropertiesToLoad.Add("modifyTimeStamp")|Out-Null

Function modiScan{
     
    forEach ($users In $userObjects) 
    { 

        $DN = $users.Properties.Item("distinguishedName")[0]
        $dnarr.add($DN)|Out-Null
    }
    #$dnarr
    foreach($dnn in $dnarr){
        $error = $false
        $lastmd = New-Object System.Collections.ArrayList
        ForEach ($DC In $Domain.DomainControllers){                    
            $Server = $DC.Name
            $Base = "LDAP://$Server/"+$dnn
            $Searcher.SearchRoot = $Base                    
            try{
                $Results2 = $Searcher.FindAll()
                ForEach ($Result2 In $Results2) 
                {   
                    $DN2 = $Result2.Properties.Item("distinguishedName")[0]
                    if($DN2 -eq $dnn){
                        $modi = $Result2.Properties.Item("modifyTimeStamp")[0]
                        if($modi){
                            $lastmd.Add($modi)|Out-Null                         
                        }
                    } 
                }
            }
            catch{
                $error = $true
            }                    
        }
        if($error -eq $true){
            $lastModi = "None-set"
            $global:noneModi++
        }
        else{
            $lastModi = ($lastmd |measure -max).maximum 
            
            if($lastModi -ne $null){   
                $lastModi = $lastModi.ToString("yyyy/MM/dd")
                if($lastModi.split("/")[0] -eq 2015){
                     $global:modi2015++
                }       
                elseif($lastModi.split("/")[0] -eq 2016){
                     $global:modi2016++
                }
                elseif($lastModi.split("/")[0] -eq 2017){
                     $global:modi2017++
                }
                 else{
                     $global:otherModi++
                }
            }
            else{
                $lastModi = "N/A"
                $global:noneModi++
            }
        }
        
      $obj = New-Object -TypeName psobject
      $obj | Add-Member -MemberType NoteProperty -Name "modi" -Value $lastModi      
      $obj | Export-Csv -Path "$outFileModi" -NoTypeInformation -append -Delimiter $Delimiter
      
   }
}
#modiScan

function modiOne{

    forEach ($users In $userObjects) 
    { 
        $modify = $users.Properties.Item("modifyTimeStamp")[0]

        if($modify -ne $null){   
            $modify = $modify.ToString("yyyy/MM/dd")
            if($modify.split("/")[0] -eq 2015){
                $global:modi2015++
            }       
            elseif($modify.split("/")[0] -eq 2016){
                         $global:modi2016++
            }
            elseif($modify.split("/")[0] -eq 2017){
                         $global:modi2017++
            }
            else{
                         $global:otherModi++
            }
        }
        else{
            $modify = "N/A"
            $global:noneModi++
        }
        
        $obj = New-Object -TypeName psobject
        $obj | Add-Member -MemberType NoteProperty -Name "modi" -Value $modify      
        $obj | Export-Csv -Path "$outFileModi" -NoTypeInformation -append -Delimiter $Delimiter
    }

}

$NeverExpires = 9223372036854775807
$userValue = @("32"
"64"
"512",
"514",
"544",
"546",
"66048",
"66050",
"66080",
"66082",
"262144",
"262656",
"262658",
"262688",
"262690",
"328192",
"328194",
"328224",
"328226")
# Supplied Attributes
$global:exportedToCSV  = $false
$global:exportedToTxt = $false
$global:ea = 0
$global:last2015 = 0
$global:last2016 = 0
$global:last2017 = 0
$global:otherLast = 0
$global:NeverLogon = 0
$global:noLastSet = 0
$global:passSet2015 = 0
$global:passSet2016 = 0
$global:passSet2017 = 0
$global:otherPassSet = 0
$global:noBadSet= 0
$global:basPassC0= 0
$global:basPassC1= 0
$global:basPassC2= 0
$global:basPassC3= 0
$global:noBadLogSet = 0
$global:uknownBadLog = 0
$global:badlog2015 =0
$global:badlog2016 =0
$global:badlog2017 =0
$global:otherBadlog =0
$global:accNotEx = 0
$global:accEx = 0
$global:accDisStatus=0
$global:smartRe =0
$global:passNotRe= 0
$global:passChangeNotAll = 0
$global:passNExpSet = 0
$global:ageNA = 0
$global:ageDate2017=0
$global:ageDate2016=0
$global:ageDate2015=0
$global:otherAgeDAte=0
$global:modi2015 =0
$global:modi2016=0
$global:modi2017=0
$global:otherModi=0
$global:noneModi=0

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
    #$lastModi= $user.Properties.Item("modifyTimeStamp")[0]
    $lockoutTime= $user.Properties.Item("lockoutTime")[0]
	$lastFailedAt = $user.Properties.item("badPasswordTime")[0]
    $Description = $user.Properties.item("Description")[0] 
    $passSet = $false
    $passTrue =$false
   
    #Last Logon
    $lastLogon = [datetime]::fromfiletime($logon)        
    $lastLogon= $lastLogon.ToString("yyyy/MM/dd")     
    if($lastLogon.split("/")[0] -eq 2015){
        $global:last2015++
    }     
    elseif ($lastLogon.split("/")[0] -eq 2016){
        $global:last2016++
    }
    elseif ($lastLogon.split("/")[0] -eq 2017){
        $global:last2017++
    }elseif ($lastLogon.split("/")[0] -eq 1601){
        $lastLogon = "Never"
        $global:NeverLogon++
    }else{
        $global:otherLast++
    }
               
    #password last set
    if($passwordLS -eq 0)
    {         
         $value = "Never"
         $global:noLastSet++
    }
    else
    {         
         $value = [datetime]::fromfiletime($passwordLS)                   
         $value = $value.ToString("yyyy/MM/dd")
         if($value.split("/")[0] -eq 2015){
             $passSet = $true
             $global:passSet2015++
         }     
         elseif ($value.split("/")[0] -eq 2016){
             $passSet = $true
             $global:passSet2016++
         }
         elseif ($value.split("/")[0] -eq 2017){
             $passSet = $true
             $global:passSet2017++
         }
         elseif ($value.split("/")[0] -eq 1601){
             $value = "Never"   
             $global:noLastSet++ 
         }
         else{
             $passSet = $true
             $global:otherPassSet++
         }
         
    }     
    #Account expires   
    if(($accountEx -eq $NeverExpires) -or ($accountEx -gt [Datetime]::MaxValue.Ticks))
    {
        $convertAccountEx = "Not Expired"
        
    }
    else
    {
        #$convertDate = [datetime]$accountEx
        $convertAccountEx = "Expired"
        $global:accEx++
    }
    #Email
    if([String]::IsNullOrEmpty($mail)){
        
        $email = "N/A"
        
    }
    else{
        $email =$mail
        $global:ea++
    }
    #PasswordCount
    if([String]::IsNullOrEmpty($passwordC)){

        $passwordCStatus = "N/A"
        $global:noBadSet++
    }
    else{

        $passwordCStatus = $passwordC   
        if($passwordC -eq 0){
            $global:basPassC0++
        }       
        elseif($passwordC -eq 1){
            $global:basPassC1++
        }
        elseif($passwordC -eq 2){
            $global:basPassC2++
        }
        else{
            $global:basPassC3++
        }
    }  
    #UserInfor
    if($accountDis -band 0x0002)
    {
        $accountDisStatus = "disabled"
        $global:accDisStatus++
    }
    else
    {
        $accountDisStatus = "none-disabled"
    }  
    #If Smartcard Required
    if( $accountDis -band 262144)
    {
        $smartCDStatus = "Required"
        $global:smartRe++
    }
    else
    {
        $smartCDStatus = "Not Required"
    }  

    #If No password is required
    if( $accountDis -band 32){
        $passwordEnforced ="Not Required"
        $global:passNotRe++
    }
    else
    {
        $passwordEnforced = "Required"
    }  

    <#If the user cannot change the password
    if( $accountDis -band 64){
        $passChange ="Not allowed"
        $global:passChangeNotAll++
    }
    else
    {
        $passChange = "Allowed"
    }
    #>
    #Password never expired
    if( $accountDis -band 0x10000){
        $passNExp ="Never Expires is set"
        $global:passNExpSet++
        
    }
    else
    {
        $passNExp = "None Set"
        $passTrue = $true
    }  
    
    #Datetime bad Logon
    if ($lastFailedAt -eq 0){
        $badLogOnTime = "Unknown"
        $global:uknownBadLog++
	}
	else{
        $badLogOnTime = [datetime]::fromfiletime($lastFailedAt)              
        $badLogOnTime= $badLogOnTime.ToString("yyyy/MM/dd")
        if($badLogOnTime.split("/")[0] -eq 2015){
            $global:badlog2015++
        }       
        elseif($badLogOnTime.split("/")[0] -eq 2016){
            $global:badlog2016++
        }
        elseif($badLogOnTime.split("/")[0] -eq 2017){
            $global:badlog2017++
        }
        elseif($badLogOnTime.split("/")[0] -eq 1601){
             $badLogOnTime = "Never"    
             $global:noBadLogSet++
        }
        else{
             $global:otherBadlog++
        }	    
   }   	  
    #maxPwdAgeValue to get expiration date
    $expDAte = $passwordLS - $maxPwdAgeValue    
    $expDAte = [datetime]::fromfiletime($expDAte) 
    if(($passTrue -eq $true)-and ($passSet -eq $true)){
        $expDAte = $expDAte.ToString("yyyy/MM/dd")
        if($expDAte.split("/")[0] -eq 2015){
            $global:ageDate2015++
        }       
        elseif($expDAte.split("/")[0] -eq 2016){
            $global:ageDate2016++
        }
        elseif($expDAte.split("/")[0] -eq 2017){
            $global:ageDate2017++
        }
        elseif($expDAte.split("/")[0] -eq 1601){
            $expDAte = "N/A"
            $global:ageNA++
        }
        else{
            $global:otherAgeDAte++
        }       
    }
    else{
        $expDAte = "N/A"
        $global:ageNA++
    } 
    #$lockoutDuration
    $obj = New-object -TypeName psobject
    $obj | Add-Member -MemberType NoteProperty -Name "Distinguished Name" -Value $dn
    $obj | Add-Member -MemberType NoteProperty -Name "Sam account" -Value $sam
    $obj | Add-Member -MemberType NoteProperty -Name "Email" -Value $email
    $obj | Add-Member -MemberType NoteProperty -Name "Password last changed" -Value $value
    $obj | Add-Member -MemberType NoteProperty -Name "Bad password count" -Value $passwordCStatus
    $obj | Add-Member -MemberType NoteProperty -Name "Last Bad Attempt" -Value $badLogOnTime 
    $obj | Add-Member -MemberType NoteProperty -Name "Last Logon " -Value $lastLogon
    $obj | Add-Member -MemberType NoteProperty -Name "Account Expires" -Value $convertAccountEx
    $obj | Add-Member -MemberType NoteProperty -Name "Account Status" -Value $accountDisStatus  
    $obj | Add-Member -MemberType NoteProperty -Name "Smartcard Required" -Value $smartCDStatus 
    $obj | Add-Member -MemberType NoteProperty -Name "Password Required" -Value $passwordEnforced  
    #$obj | Add-Member -MemberType NoteProperty -Name "Password Change" -Value $passChange  
    $obj | Add-Member -MemberType NoteProperty -Name "Never Expired Password Set" -Value $passNExp  
    $obj | Add-Member -MemberType NoteProperty -Name "Password Expiration Date" -Value $expDAte
    #$obj | Add-Member -MemberType NoteProperty -Name "Last Modified" -Value $lastModi    
    $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $Description  
    if($exportCheck -eq $true){    
            $global:exportedToCSV = $true
            $obj | Export-Csv -Path "$outFile" -NoTypeInformation -append -Delimiter $Delimiter        
    }
    else
    {
        $obj 
    }      
}
#Main run here
$cls = cls
function main{
    $ADSearch.SearchRoot ="LDAP://$Domain"
    # distinguished Name method
    $arrayDN = @()
    if($dna -eq $true)
    {
        if($amountCheck -eq $true)
        {
            Write-Host
            Write-Verbose -Message  "Please be patient whilst the script retrieves all $global:amount distinguished names..." -Verbose        
        
            foreach ($user  in $userObjects)
            {
                if($count -lt $global:amount)
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
                    Write-Progress -Activity "Processing $($global:amount) Users" -Status ("Count: 
                    $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$global:amount)*100)
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
        Write-Verbose -Message  "Please be patient whilst the script retrieves all $global:amount distinguished names..." -Verbose
        foreach ($user  in $userObjects)
        {
            if($count -lt $global:amount)
            {
                tracking
                $TotalUsersProcessed++
                $count++
                If ($ProgressBar) 
                {                
                    Write-Progress -Activity "Processing $($global:amount) Users" -Status ("Count: 
                    $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$global:amount)*100)              
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
    # Scann all DC's
    write-host
    $global:allDC = Read-Host -Prompt "Do you want to scan all DC's (y/n)? (it will take for a long while to finish)"
    if(($global:allDC -eq "y") -or ($global:allDC -eq "")){
        $global:allDC = $true
    }
    elseif($global:allDC -eq "n"){
        $global:allDC = $false
    }
    else{

        Write-Verbose -Message "Option is not valid" -Verbose
    }
    #Amount
    $global:amount = Read-Host -Prompt "Amount of data (Enter to get all data)"
    if($global:amount -eq ""){        
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
        if($global:allDC -eq $true){
            modiScan
        }
        if($global:allDC -eq $false){
            modiOne
        }
        $CSV1 = Import-Csv $outFileModi
        $CSV2 = Import-Csv $outFile

        $CSV2 | ForEach-Object -Begin {$i = 0} {  
        $_ | Add-Member -MemberType NoteProperty -Name "User's Objects lastest Modification" -Value $CSV1[$i++].modi -PassThru 
                    } | Export-Csv $outFileMeg -NoTypeInformation
        rm $outFileModi
        rm $outFile
        Write-Host "Data has been exported to $outFileMeg" -foregroundcolor "magenta"
}
if($exportedToTxt -eq $true){
        Write-Host
        Write-Host "Data has been exported to $outFileTxt" -foregroundcolor "magenta"
}
$global:IncludeImages = New-Object System.Collections.ArrayList 
$global:check= 0
$global:outFilePicPie = $($PSScriptRoot)+"\Pie-$($dateTimeFile)-$($global:check).jpeg"
#PIE
    #Email
$emailPer = $global:ea 
#$emailPer= [math]::Round($emailPer,2)
$noEmailPer=  $userCount - $emailPer
$mailHash = @{"Available"=$emailPer;"Unavailable"=$noEmailPer}
    #Account expired
$accExPer = $global:accEx
#$accExPer = [math]::Round($accExPer,2)
$accNotExPer = $userCount - $accExPer
$accExHash = @{"Expired"="$accExPer";"Unexpired"="$accNotExPer"}
    #Account Status
$accDisPer = $global:accDisStatus 
#$accDisPer = [math]::Round($accDisPer,2)
$accNoDisPer = $userCount - $accDisPer
$accStatusHash = @{"Disabled"="$accDisPer";"Enabled"="$accNoDisPer"}
    #Smart Card required
$smartRePer = $global:smartRe
#$smartRePer = [math]::Round($smartRePer,2)
$smartNotRePer = $userCount - $smartRePer
$smartReHash = @{"Required"="$smartRePer";"Not Required"="$smartNotRePer"}
    #Password Required
$passReNotPer = $global:passNotRe 
#$passReNotPer = [Math]::Round($passReNotPer,2)
$passRePer =  $userCount - $passReNotPer
$passReHash = @{"Not Required"="$passReNotPer";"Required"="$passRePer"}
    #Password Changed
$passChangeNotAllPer = $global:passChangeNotAll
#$passChangeNotAllPer = [math]::Round($passChangeNotAllPer,2)
$passChangeAllper =  $userCount - $passChangeNotAllPer
$passChangedHash = @{"Allowed"="$passChangeAllper";"Not Allowed"="$passChangeNotAllPer";}
    #Password Never Expired Set
$passExpSetPer =$global:passNExpSet
#$passExpSetPer = [math]::Round($passExpSetPer)
$passExpNoSetPer= $userCount - $passExpSetPer
$passExpHash = @{"Set"="$passExpSetPer";"None-set"="$passExpNoSetPer"}
Function drawPie {
    param($hash,
    [string]$title
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms.DataVisualization
    $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $Series = New-Object -TypeName System.Windows.Forms.DataVisualization.Charting.Series
    $ChartTypes = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]
    $Series.ChartType = $ChartTypes::Pie
    $Chart.Series.Add($Series)
    $Chart.ChartAreas.Add($ChartArea)
    $Chart.Series['Series1'].Points.DataBindXY($hash.keys, $hash.values)
    $Chart.Series[‘Series1’][‘PieLabelStyle’] = ‘Disabled’
    $Legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $Legend.IsEquallySpacedItems = $True
    $Legend.BorderColor = 'Black'
    $Chart.Legends.Add($Legend)
    $chart.Series["Series1"].LegendText = "#VALX (#VALY)"
    $Chart.Width = 700
    $Chart.Height = 400
    $Chart.Left = 10
    $Chart.Top = 10
    $Chart.BackColor = [System.Drawing.Color]::White
    $Chart.BorderColor = 'Black'
    $Chart.BorderDashStyle = 'Solid'
    $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $ChartTitle.Text = $title
    $Font = New-Object System.Drawing.Font @('Microsoft Sans Serif','12', [System.Drawing.FontStyle]::Bold)
    $ChartTitle.Font =$Font
    $Chart.Titles.Add($ChartTitle)
    $testPath = Test-Path $global:outFilePicPie
    if($testPath -eq $True){
        $global:check += 1      
        $global:outFilePicPie = $($PSScriptRoot)+"\Pie-$($dateTimeFile)-$($global:check).jpeg"                 
    }
    $global:IncludeImages.Add($global:outFilePicPie)
    $Chart.SaveImage($outFilePicPie, 'jpeg')  
}
#BAR
    #lastLogon
$lastLogonHash = [ordered]@{"Never"="$global:NeverLogon";"<2015"="$global:otherLast";"2015"="$global:last2015";"2016"="$global:last2016";"2017"="$global:last2017"}
$global:check1= 0
$global:outFilePicBar = $($PSScriptRoot)+"\Bar-$($dateTimeFile)-$($global:check).jpeg"
    #PassLastSet
$passSetHash = [ordered]@{"Never"="$global:noLastSet";"<2015"="$global:otherPassSet";"2015"="$global:passSet2015";
                        "2016"="$global:passSet2016";"2017"="$global:passSet2017";}
    #BadPassCount
$badPassCHash = [ordered]@{"N/A"="$global:noBadSet";"0"="$global:basPassC0";"1"="$global:basPassC1";
                            "2"="$global:basPassC2";"3"="$global:basPassC3" }
    #Last bad Attempt
$lastBadLogHash = [ordered]@{"Unknown"="$global:uknownBadLog";"Never"="$global:noBadLogSet";"<2015"="$global:otherBadlog";"2015"="$global:badlog2015";"2016"="$global:badlog2016";"2017"="$global:badlog2017"}
    #password Age   
$ageHash = [ordered]@{"N/A"="$global:ageNA";"<2015"="$global:otherAgeDAte";"2015"="$global:ageDate2015";
                                "2016"="$global:ageDate2016";"2017"="$global:ageDate2017" }
    #Last Modi
    
$lastModihash = [ordered]@{ "N/A"=$global:noneModi++;"<2015"="$global:otherModi";"2015"="$global:modi2015";
                                "2016"="$global:modi2016";"2017"="$global:modi2017"}

function drawBar{
    param(
    $hash,[string]$title
    ) 
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms.DataVisualization
    $Chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    $ChartArea1 = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $Series1 = New-Object -TypeName System.Windows.Forms.DataVisualization.Charting.Series
    $ChartTypes1 = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]
    #$Series1.ChartType = $ChartTypes1::Bar
    $Chart1.Series.Add($Series1)
    $Chart1.ChartAreas.Add($ChartArea1)
    #$Chart1.Series.Add("dataset") | Out-Null
    $Chart1.Series[‘Series1’].Points.DataBindXY($hash.keys, $hash.values)
    $chart1.Series[0].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column 
    #$Chart1.Series['Series1'].Points.DataBindXY($hash.keys, $hash.values)
    $ChartArea1.AxisX.Title = "Years"
    $ChartArea1.AxisY.Title = "Figures"
    $Chart1.Series[‘Series1’].IsValueShownAsLabel = $True
    $Chart1.Series[‘Series1’].SmartLabelStyle.Enabled = $True
    $chart1.Series[‘Series1’]["LabelStyle"] = "TopLeft"
    #$chart1.Series[0]["PieLabelStyle"] = "Outside" 
    ##$chart1.Series[0]["DrawingStyle"] = "Emboss" 
    #$chart1.Series[0]["PieLineColor"] = "Black" 
    #$chart1.Series[0]["PieDrawingStyle"] = "Concave"

    if($global:amount){
        $ChartArea1.AxisY.Maximum = $global:amount
        if($userCount -ge 1000){
            $ChartArea1.AxisY.Interval = $inter - ($inter %100)
            $inter = [math]::Round($userCount/10,0)
        }elseif($userCount -ge 100){
            $ChartArea1.AxisY.Interval = $inter - ($inter %10)
            $inter = [math]::Round($userCount/20,0)
        }else{
            $ChartArea1.AxisY.Interval = $inter - ($inter %10)
            $inter = [math]::Round($userCount/10,0)
        }
    }else{
        $ChartArea1.AxisY.Maximum = $userCount
        
        if($userCount -ge 1000){
            $ChartArea1.AxisY.Interval = $inter - ($inter %100)
            $inter = [math]::Round($userCount/10,0)
        }elseif($userCount -ge 100){
            $ChartArea1.AxisY.Interval = $inter - ($inter %10)
            $inter = [math]::Round($userCount/20,0)
        }else{
            $ChartArea1.AxisY.Interval = $inter - ($inter %10)
            $inter = [math]::Round($userCount/10,0)
        }

    }
    
    $Chart1.Width = 1000
    $Chart1.Height = 700
    $Chart1.Left = 10
    $Chart1.Top = 10
    $Chart1.BackColor = [System.Drawing.Color]::White
    $Chart1.BorderColor = 'Black'
    $Chart1.BorderDashStyle = 'Solid'      
    $ChartTitle1 = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $ChartTitle1.Text = $title
    $Font1 = New-Object System.Drawing.Font @('Microsoft Sans Serif','12', [System.Drawing.FontStyle]::Bold)
    $ChartTitle1.Font =$Font1
    $Chart1.Titles.Add($ChartTitle1)

    $testPath = Test-Path $global:outFilePicBar
    if($testPath -eq $True){
        $global:check1 += 1      
        $global:outFilePicBar = $($PSScriptRoot)+"\Bar-$($dateTimeFile)-$($global:check1).jpeg"         
    }
    $global:IncludeImages.Add($global:outFilePicBar)
    $Chart1.SaveImage("$outFilePicBar", 'jpeg')
}
drawPie -hash $mailHash -title "Emails Availability" |Out-Null
drawPie -hash $accExHash -title "Expired Accounts"|Out-Null
drawPie -hash $accStatusHash -title "Account Status"|Out-Null
drawPie -hash $smartReHash -title "Smart Cards Required"|Out-Null
drawPie -hash $passReHash -title "Password Required"|Out-Null
#drawPie -hash $passChangedHash -title "Password CANNOT Change"|Out-Null
drawPie -hash $passExpHash -title "Password Never Expired Settings"|Out-Null
drawBar -hash $lastLogonHash -title  "Last Logon Date"|Out-Null
drawBar -hash $passSetHash -title "Password Last Changed"|Out-Null
#drawBar -Hash $badPassCHash -title "Bad Password Count"|Out-Null
drawBar -hash $lastBadLogHash -title "Last Bad Logon Attempts"|Out-Null
drawBar -hash $ageHash -title "Password Expiration Date"|Out-Null
drawBar -hash $lastModihash -title "User's Objects Latest Modification"|Out-Null
$userName = Get-ADUser -filter * -Properties DistinguishedName| ?{$_.sAMAccountName -match $env:UserName }|select Name|Out-String
$userName = $userName -replace '-', ' ' -replace 'Name', ''
$userName = $userName.Trim()
$trustedDo = Get-ADTrust -Filter * -Server $Domain | select Name |Out-String
$trustedDo = $trustedDo  -replace '-','' -replace 'Name','' 
$trustedDo =$trustedDo.Trim()
$adForest =  (get-ADForest -Server $Domain).domains | Out-String
if([string]::IsNullOrEmpty($global:amount)){
    $global:amount = $userCount
}
$admin = Get-ADGroupMember "Domain ADmins" -Server $Domain| select name,distinguishedName |measure
$admin = $admin.count
$domainCName = Get-ADDomainController -Filter * -Server $Domain| select Name|Out-String
$domainCName = $domainCName -replace '-', ' ' -replace 'Name', ''
$domainCName = $domainCName.Trim()
$domainCoper = Get-ADDomainController -Filter * -Server $Domain| select operatingsystem|Out-String
$domainCoper = $domainCoper -replace '-', ' ' -replace 'Name', '' -replace 'operatingsystem',''
$domainCoper = $domainCoper.Trim()
$ipAddress = Get-NetIPAddress | ?{($_.InterfaceAlias -match "Public") -and ($_.AddressFamily -match "Ipv4")}|select IPAddress|Out-String
$ipAddress = $ipAddress -replace '-', ' ' -replace 'IPAddress', ''
$ipAddress = $ipAddress.Trim()
$body =@'
<h1> Forest Report </h1>
<p><ins><b>I.<b> Information<ins></p>
<div class="tabofexecu">
    <table class="tabexecu" >
 
          <tr>
            <td>Object Category:</td>
            <td>{8}</td> 
          </tr>
          <tr>
            <td>Object Class: </td>
            <td>{9}</td> 
          </tr>
  
          <tr>
            <td>Amount of Data: </td>
            <td>{10}</td> 
          </tr>      
    </table>
<div>

<div class="tablehere">
    <table class="tabinfo" > 
          <tr>
            <td>Domain:</td>
            <td>{0}</td> 
          </tr>
          <tr>
            <td>User Domain: </td>
            <td>{1}</td> 
          </tr>
          <tr>
            <td>Computer Name:</td>
            <td>{2}</td> 
          </tr>
          <tr>
            <td>IP Address:</td>
            <td>{14}</td> 
          </tr>
          <tr>
            <td>Reported by: </td>
            <td>{3}</td> 
          </tr>
          <tr>
            <td>Execution Date: </td>
            <td>{4}</td> 
          </tr>
          <tr>
            <td>Retrieved Data from: </td>
            <td>{5}</td> 
          </tr>
    </table>
</div>

<p><ins><b>II.<b> Domain Summary<ins></p>
<div  class="secTable">
    <table class="tabforest" > 
          <tr>
            <td>Number of Domain Admins:</td>
            <td>{11}</td> 
          </tr>

          <tr>
            <td>Forest Domains:</td>
            <td>{6}</td> 
          </tr>
          <tr>
            <td>Trusted Domains: </td>
            <td>{7}</td> 
          </tr>
    </table>
</div>
<div class="tabdomaincon">
    <table class="tabdomain" > 
        <tr>
            <th>Domain Controllers</th>
            <th>Operating System</th> 
        </tr>
        <tr>           
            <td>{12}</td> 
            <td>{13}</td> 
        </tr>      
    </table>
<div>

<p><ins><b>III.<b> Data Illustration<ins></p>
'@ -f  $Domain ,$env:UserDomain, $env:ComputerName,$userName,$(get-date),$outFileMeg,$adForest,$trustedDo,$objectCategory,$objectClass,$global:amount,$admin,$domainCName,$domainCoper,$ipAddress

function Generate-Html {
    Param(
        [Parameter()]
        [string[]]$IncludeImages
    )

    if ($IncludeImages){
        $ImageHTML = $IncludeImages | % {
        $ImageBits = [Convert]::ToBase64String((Get-Content $_ -Encoding Byte))
        "<center><img src=data:image/jpeg;base64,$($ImageBits) alt='My Image'/><center>"
    }
        ConvertTo-Html -Body $body -PreContent $imageHTML -Title "Report on $Domain" -CssUri "style.css" |
        Out-File $outFileHTML
    }
}

Generate-Html -IncludeImages $global:IncludeImages


foreach($image in $IncludeImages){

    rm $image 
}
#Finish
Write-Host
Write-Verbose -Message  "Script Finished!!" -Verbose
