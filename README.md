# Wiki

Here: https://github.com/enderphan94/Learn-Power-Shell/wiki


# About AD Tracking

It's being developed....

- Powershell Version 4
- Windows 7
- Run as regular user

# Usages 1.0

Suppy the objectClass (Eg: user, group, person...)



![Alt text](/image/ADTracking.png?raw=true "map")

# Just Enumerate Distinguished name

- Enumerate Distinguished name and print it to console:

    `.\adTracking.ps1 -dna`           
    
- Write Distinguished name to text file:

    `.\adTracking.ps1 -dna -addToReport` 
   
- Write Distinguished name to text file with specific amout of data:

     `.\adTracking.ps1 -dna -addToReport -amount 100`   
     
- Print given amount of Distinguished name to console:

    `.\adTracking.ps1 -dna -amount 100 `     

# Get All attributes

- Enumerate  all supplied LDAP Attributes and print it to console:

    `.\adTracking.ps1`
    
- Write all data to CSV file:

    `.\adTracking.ps1 -addToReport` 
    
- Write data to CSV file with given amount of data:

    `.\adTracking.ps1 -addToReport -amount 100`
    
- Print given amount of data to console :

    `.\adTracking.ps1 -amount 100 `    


# Usages 1.2

You just need to follow the tools instruction

- Updates:

    + Added the trusted domain method
    
    + Fixed Account expires function
    
    + Change parameters to optional methods
    
- Cool Functions:

    + Free to run the tool on current domain or trusted domain
    
    + List all trusted domain by using `Get-ADTrust` ( Windows 2012 or higher )
    
    + Able to scan un-replicated attributes. It will go to each DC's and get the most proper values
    
    + Giving out a colorful HTML report which contains information of domain, domain summary and data illustration with pie charts and bar graphs
    

