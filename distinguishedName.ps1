#Dev by Ender Loc Phan

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()

$ADSearch = New-Object System.DirectoryServices.DirectorySearcher
$ADSearch.SearchRoot ="LDAP://$Domain"


$ADSearch.SearchScope = "subtree"
$ADSearch.PageSize = 100

$ADSearch.Filter = "(objectClass=user)"


$properies = "distinguishedName"


foreach($pro in $properies){
    $ADSearch.PropertiesToLoad.add($pro)
}

$userObjects = $ADSearch.FindAll()

$count = 0;


foreach ($user  in $userObjects){

    if($count -lt 10){       
    
        $dn =  $user.Properties.Item("distinguishedName")
        $dn
        
        $count++   
              
    }

    
}


