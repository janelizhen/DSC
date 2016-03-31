<#
    Preparations
    
    1. On local node
       Enable-PSRemoting –force
       winrm s winrm/config/client '@{TrustedHosts="*"}'

    2. On remote node
       Create a user who is
       1) in admin group; 
       2) in remote management group;
       3) remote enabled for DesiredStateConfiguration namespace in WMI security
#>

configuration Desired_Config_On_Remote_IPv6_Node
{
    File file
    {
        DestinationPath = "$env:SystemDrive\test.txt"
        Contents = "test"
    }
}

Desired_Config_On_Remote_IPv6_Node -outputPath C:\Demo


$configData = @{
    AllNodes = @(
        @{
            NodeName = $env:COMPUTERNAME
            PSDscAllowPlainTextPassword = $true
        }
    )
}

configuration Config_Used_On_Local_Node_To_Deploy
{
    Import-DscResource -ModuleName IPv6Node

    Node $env:COMPUTERNAME
    {
        IPv6NodeResource Node
        {
            IPv6Address = "2001:4898:d8:f22e:b889:9a9d:dff3:8516"
            ConfigurationFilePath = "C:\Demo\localhost.mof"
            Credential = (Get-Credential)
        }
    }
}

foo -outputPath C:\Demo\local -ConfigurationData $configData
