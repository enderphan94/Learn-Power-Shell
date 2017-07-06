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

$Domain = $Domain.PdcRoleOwner

$ADSearch = New-Object System.DirectoryServices.DirectorySearcher
#new empty ad search, search engine someth we can send queries to find out

$ADSearch.SearchRoot ="LDAP://$Domain"
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

$NowUtc = (Get-Date).ToFileTimeUtc()
$lockoutTimeValue = $NowUtc + $duraValue

if(-$duraValue -gt [datetime]::MaxValue.Ticks){


}

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
$userCount =  $userObjects.Count
$result = @()
$count = 0

# Creating csv file

$invalidChars = [io.path]::GetInvalidFileNameChars()
$dateTimeFile = ((Get-Date -Format s).ToString() -replace "[$invalidChars]","-")
$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$outFile = $($PSScriptRoot)+"\$($Domain)-Report-$($dateTimeFile).csv"
$outFileTxt = $($PSScriptRoot)+"\Report-$($dateTimeFile).txt"
$Delimiter = ","
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
    $lastModi= $user.Properties.Item("modifyTimeStamp")[0]
    $lockoutTime= $user.Properties.Item("lockoutTime")[0]
	$lastFailedAt = $user.Properties.item("badPasswordTime")[0]
    $Description = $user.Properties.item("Description")[0]
 
    
    #last Logon
    if($logon.Count -eq 0)
    {
        $lastLogon = "Never logon"
        $global:NeverLogon++
    }
    else
    {        
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
        }else{

            $global:otherLast++
        }
          
    }
   
    #password last set
    if($passwordLS -eq 0)
    {         
         $value = "Not set"
         $global:noLastSet++
    }
    else
    {         
         $value = [datetime]::fromfiletime($passwordLS)                
         if($value -eq $("1/1/1601 01:00:00" | Get-Date)){
                $value = "Not set"   
                $global:noLastSet++ 
         }
         else{

            $value = $value.ToString("yyyy/MM/dd")
            if($value.split("/")[0] -eq 2015){
                $global:passSet2015++
            }     
            elseif ($value.split("/")[0] -eq 2016){
                $global:passSet2016++
            }
            elseif ($value.split("/")[0] -eq 2017){
                $global:passSet2017++
            }else{

                $global:otherPassSet++
            }
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
    }
    else
    {
        $smartCDStatus = "Not Required"
    }  

    #If Smartcard Required
    if( $accountDis -band 0x40000)
    {
        $smartCDStatus = "Required"
    }
    else
    {
        $smartCDStatus = "Not Required"
    }  

    #If No password is required
    if( $accountDis -band 32){
        $passwordEnforced ="Not Required"
    }
    else
    {
        $passwordEnforced = "Required"
    }  

    #If the user cannot change the password
    if( $accountDis -band 64){
        $passChange ="Not allowed"
    }
    else
    {
        $passChange = "Allowed"
    }

    #Password never expired
    if( $accountDis -band 0x10000){
        $passNExp ="Never Expires is set"
    }
    else
    {
        $passNExp = "None Set"
    }  

    # Last Modified    
    $lastModi = $lastModi.ToString("yyyy/MM/dd")
    
    #Datetime bad Logon
    if ($lastFailedAt -eq 0){
        $badLogOnTime = "Unknown"
        $global:uknownBadLog++
	}
	else{
        $badLogOnTime = [datetime]::fromfiletime($lastFailedAt)                
        if($badLogOnTime -eq $("1/1/1601 01:00:00" | Get-Date))
        {        
            $badLogOnTime = "Not set"    
            $global:noBadLogSet++
        }
        else{
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
            else{
                $global:otherBadlog++
            }
	    }
   }
	   
	  
    #maxPwdAgeValue to get expiration date

    $expDAte = $passwordLS - $maxPwdAgeValue    
    $expDAte = [datetime]::fromfiletime($expDAte) 
    if($expDAte -eq $("02/15/1601 01:00:00" | Get-Date)){

        $expDAte = "N/A"
    }
    else{
        $expDAte = $expDAte.ToString("yyyy/MM/dd")

       
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
    $obj | Add-Member -MemberType NoteProperty -Name "Password Change" -Value $passChange  
    $obj | Add-Member -MemberType NoteProperty -Name "Never Expired Password Set" -Value $passNExp  
    $obj | Add-Member -MemberType NoteProperty -Name "Password Expiration Date" -Value $expDAte
    $obj | Add-Member -MemberType NoteProperty -Name "Last Modified" -Value $lastModi
    #$obj | Add-Member -MemberType NoteProperty -Name "Lockout Time" -Value $lockoutTimeStatus
    $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $Description
     
   
    if($exportCheck -eq $true){
      
            $global:exportedToCSV = $true
            $obj | Export-Csv -Path "$outFile" -NoTypeInformation -append -Delimiter $Delimiter
          
    }
    else
    {
        $badLogOnTime 
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



$global:IncludeImages = New-Object System.Collections.ArrayList 
#[byte[]]$file = Get-Content image.jpeg -Encoding byte
$global:check= 0
$global:outFilePicPie = $($PSScriptRoot)+"\Pie-$($dateTimeFile)-$($global:check).jpeg"
#PIE
    #Email
$emailPer = ($global:ea * 100)/$userCount
$emailPer= [math]::Round($emailPer,2)
$noEmailPer=  100 - $emailPer
$mailHash = @{"Email Set"=$emailPer;"No Email"=$noEmailPer}
    #Account expires
$accExPer = ($global:accEx *100)/$userCount
$accExPer = [math]::Round($accExPer,2)
$accNotExPer = 100 - $accExPer
$accExHash = @{"Expired"="$accExPer";"Not Expired"="$accNotExPer"}
    #Account Status
$accDisPer = ($global:accDisStatus * 100)/$userCount
$accDisPer = [math]::Round($accDisPer,2)
$accNoDisPer = 100 - $accDisPer
$accStatusHash = @{"Disable"="$accDisPer";"None-Disbale"="$accNoDisPer"}

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
    $chart.Series["Series1"].LegendText = "#VALX (#VALY%)"
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
$lastLogonHash = [ordered]@{"2017"="$global:last2017";"2016"="$global:last2016"
            ;"2015"="$global:last2015";"<2015"="$global:otherLast";"Never"="$global:NeverLogon"}
$global:check1= 0
$global:outFilePicBar = $($PSScriptRoot)+"\Bar-$($dateTimeFile)-$($global:check).jpeg"

    #PassLastSet
$passSetHash = [ordered]@{"2017"="$global:passSet2017";"2016"="$global:passSet2016";"2015"="$global:passSet2015";
                                    "<2015"="$global:otherPassSet";"Not Set"="$global:noLastSet"}
    #BadPassCount
$badPassCHash = [ordered]@{"3"="$global:basPassC3";"2"="$global:basPassC2";"1"="$global:basPassC1"
                                       "0"="$global:basPassC0";"N/A"="$global:noBadSet" }

    #Last bad Attempt
$lastBadLogHash = [ordered]@{"2017"="$global:badlog2017";"2016"="$global:badlog2016";"2015"="$global:badlog2015"
                                              "Unknown"="$global:uknownBadLog";"Not set"="$global:noBadLogSet"}

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
    $Series1.ChartType = $ChartTypes1::Bar
    $Chart1.Series.Add($Series1)
    $Chart1.ChartAreas.Add($ChartArea1)
    $Chart1.Series['Series1'].Points.DataBindXY($hash.keys, $hash.values)
    $ChartArea1.AxisX.Title = "Years"
    $ChartArea1.AxisY.Title = "Figures"
    $ChartArea1.AxisY.Maximum = $userCount
    $ChartArea1.AxisY.Interval = 10
    #$ChartArea1.AxisY.IntervalOffset = 5
    $Chart1.Width = 700
    $Chart1.Height = 400
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


drawPie -hash $mailHash -title "Mail"
drawPie -hash $accExHash -title "Account Expires"
drawPie -hash $accStatusHash -title "Account Status"
drawBar -hash $lastLogonHash -title  "Last Logon Time"
drawBar -hash $passSetHash -title "Password Last Changed"
drawBar -Hash $badPassCHash -title "Bad Password Count"
drawBar -hash $lastBadLogHash -title "Last bad Attempt date"
$IncludeImage
#$global:IncludeImages
function Generate-Html {
    Param(
        [Parameter()]
        [string[]]$IncludeImages
    )

    if ($IncludeImages){
        $ImageHTML = $IncludeImages | % {
        $ImageBits = [Convert]::ToBase64String((Get-Content $_ -Encoding Byte))
        "<img src=data:image/jpeg;base64,$($ImageBits) alt='My Image'/>"
    }
        ConvertTo-Html -Body $style -PreContent $imageHTML |
        Out-File "C:\Users\p998wph\Documents\Ender\test2.htm"
    }
}

Generate-Html -IncludeImages $global:IncludeImages


foreach($image in $IncludeImages){

    rm $image
}
#Finish
Write-Host
Write-Verbose -Message  "Script Finished!!" -Verbose
