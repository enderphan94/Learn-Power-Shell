#Dev by Ender Loc Phan

param(

[int]$amount,
[switch]$dna,
[switch]$userex,
[switch]$userstatus

)
Write-Verbose -Message  "This script is running under PowerShell version $($PSVersionTable.PSVersion.Major)" -Verbose

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()

$ADSearch = New-Object System.DirectoryServices.DirectorySearcher
#new empty ad search, search engine someth we can send queries to find out

$ADSearch.SearchRoot ="LDAP://$Domain"
#where we wanna look in LDAP is Domain, because we don't wanna search from root
#root is: $objDomain = New-Object System.DirectoryServices.DirectoryEntry

$ADSearch.SearchScope = "subtree"
$ADSearch.PageSize = 100

$ADSearch.Filter = "(objectClass=user)"
#where objectClass attribute are -eq to user
#Atribute to search for: ObjectClass
# value of attribute : user
#exp: $ADSearch.Filter = "(Name=Ender)"

 
$properies = "distinguishedName","sAMAccountName","mail","lastLogonTimeStamp","pwdLastSet","accountExpires","userAccountControl"
#values in array are atttibute of LDAP



foreach($pro in $properies){

    $ADSearch.PropertiesToLoad.add($pro)
    #the name of property of the object, search will load the name in an array #properties
}


$ProgressBar = $True
$userObjects = $ADSearch.FindAll()
$userCount =  $userObjects.Count
$result = @()
$count = 0;
$csvFileName = "Y:\Powershell\adTracking.csv"
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

## distinguished Name method
$arrayDN = @()
if($dna){    
    
    if($amount){
            
        Write-Verbose -Message  "Please be patient whilst the script retrieves all $amount distinguished names..." -Verbose        
       
        foreach ($user  in $userObjects){        
            If ($ProgressBar) {
                Write-Progress -Activity "Processing $($amount) Users" -Status ("Count: $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$amount)*100)
            }
            if($count -lt $amount){
                $sam = $user.Properties.Item("sAMAccountName")
                $dn =  $user.Properties.Item("distinguishedName")
                $arrayDN += $dn 
                $count++    
                $TotalUsersProcessed++          
            }     
        }
        $arrayDN
   
    }    
    else{
    Write-Verbose -Message  "Please be patient whilst the script retrieves all $userCount distinguished names..." -Verbose
        foreach ($user  in $userObjects){
                If ($ProgressBar) {
                    Write-Progress -Activity "Processing $($userCount) Users" -Status ("Count: $($TotalUsersProcessed)- Username: {0}" -f $sam) -PercentComplete (($TotalUsersProcessed/$userCount)*100)
                }
                $sam = $user.Properties.Item("sAMAccountName")
                $dn =  $user.Properties.Item("distinguishedName")
                $arrayDN += $dn
                $TotalUsersProcessed++
            }
        
        $arrayDN
    }
    
}
## Finish distinguished Name method


else{
foreach ($user  in $userObjects){

    if($count -lt 10){
        <#
        $thisObject = New-Object System.Object
        foreach ($property in $user.Properties.PropertyNames){


            $thisObject | Add-Member -type NoteProperty -Name $property -Value $user.Properties.Item($property)
        }
           
        $result += $thisObject
        #>
        $dn =  $user.Properties.Item("distinguishedName")
        
        $sam = $user.Properties.Item("sAMAccountName")
        $logon = $user.Properties.Item("lastLogonTimeStamp")
        $mail =$user.Properties.Item("mail")
        $passwordLS = $user.Properties.Item("pwdLastSet")
        $accountEx = $user.Properties.Item("accountExpires")
        $accountDis= $user.Properties.Item("userAccountControl")

        if($logon.Count -eq 0){
            $lastLogon = "Never"
        }
        else{
        
            $lastLogon = [DateTime]$logon[0]

        }

        $value = [DateTime]::FromFileTime($passwordLS[0])

        if($accountEx.accountExpires -eq 0){
                $convertAccountEx = "Never"
        }
        else{
                $convertAccountEx = [DateTime]::FromFileTime($AccountEx.accountExpires)                
        }
        
        if($accountDis -eq 512){
                $accountDisStatus = "User is disbled"
        }else{
                $accountDisStatus = "User ready for logon"

        }
        
        #$accountDis
       
        if(($dn -match "OU=EE" )){

            #$result +=$dn,$sam,$mail,$value,$lastLogon,$convertAccountEx

           """$dn"",$sam,$mail,'password change: '$value,'last logon: '$lastLogon,'account expired: ' $convertAccountEx,'account status: '$accountDisStatus"
           $count++;       
       
        }
    }
    
    
}
}
#$result


Write-Host
Write-Verbose -Message  "Script Finished!!" -Verbose
