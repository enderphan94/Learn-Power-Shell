# Wiki

Here: https://github.com/enderphan94/Learn-Power-Shell/wiki


# About AD Tracking

It's being developed....

- Powershell Version 4
- Windows 7
- Run as regular user

# Usages 

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


