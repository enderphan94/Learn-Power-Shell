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

$properies = "distinguishedName","sAMAccountName","lastLogonTimeStamp"

foreach($pro in $properies){

    $ADSearch.PropertiesToLoad.add($pro)
    #the name of property of the object, search will load the name in an array #properties
}



$userObjects = $ADSearch.FindAll()

$count = 0;

foreach ($user  in $userObjects){

    if($count -lt 10){
        $dn =  $user.Properties.Item("distinguishedName")
        $sam = $user.Properties.Item("sAMAccountName")
        $logon = $user.Properties.Item("lastLogonTimeStamp")

        if($logon.Count -eq 0){
            $lastLogon = "Never"
        }
        else{
        
            $lastLogon = [DateTime]$logon[0]

        }
    
        if($dn -match "OU=EE"){
           """$dn"",$sam,$lastLogon"
           $count++;
        }
       
       
    }

    
}
