<# Authorize a configuration for particular node #>
configuration config
{
    #Node $computer_name
    #Node $ipv4_address
    #Node $ipv6_address <-- not working
    Node localhost
    {
        ...
    }
}
config
Start-DscConfiguration -Path .\config -Wait -Verbose -Force

<# A workaround #>
function Get-EncodedMofFile
{
    param([string]$configurationFilePath)
    $mofDocument = [System.IO.File]::ReadAllBytes($configurationFilePath)
    $totalLength = $mofDocument.Length + 4
    $encodedMof = New-Object Byte[] $totalLength
    $encoding = [System.BitConverter]::GetBytes($totalLength)
    $index = 0
    foreach ($var in $encoding)
    {
        $encodedMof[$index++] = $var
    }
    foreach ($var in $mofDocument)
    {
        $encodedMof[$index++] = $var
    }
    $encodedMof
}

$encodedMof = Get-EncodedMofFile -configurationFilePath ".\config\localhost.mof"
$session = New-CimSession -ComputerName $IPv6Address -Credential $Credential
Invoke-CimMethod -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager -MethodName SendConfigurationApply -Arguments @{ConfigurationData=$encodedMof;Force=$true} -Verbose -CimSession $session
$session | Remove-CimSession

<# An even simplified way with above functionality and test/get wrapped in a class resource @ https://github.com/janelizhen/DSC.git #>

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

$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "jane-test-1\testuser", ("P@ssword" | ConvertTo-SecureString -AsPlainText -Force)

configuration Config_Used_On_Local_Node_To_Deploy
{
    Import-DscResource -ModuleName IPv6Node

    Node $env:COMPUTERNAME
    {
        IPv6NodeResource Node
        {
            IPv6Address = "2001:4898:d8:a195:90f4:422b:c3e6:ac5f"
            ConfigurationFilePath = "C:\Demo\localhost.mof"
            Credential = $credential
        }
    }
}

Config_Used_On_Local_Node_To_Deploy -outputPath C:\Demo\remote -ConfigurationData $configData
Start-DscConfiguration -Path C:\Demo\remote -Wait -Verbose -Force

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
