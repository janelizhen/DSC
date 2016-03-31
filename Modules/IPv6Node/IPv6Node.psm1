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

[DscResource()]
class IPv6NodeResource
{
    [DscProperty(Key)]
    [string]$IPv6Address
    
    [DscProperty(Key)]
    [string]$ConfigurationFilePath
    
    [DscProperty()]
    [PsCredential]$Credential


    [void] Set()
    {
        $encodedMof = Get-EncodedMofFile -configurationFilePath $this.ConfigurationFilePath
        $session = New-CimSession -ComputerName $this.IPv6Address -Credential $this.Credential
        Invoke-CimMethod -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager -MethodName SendConfigurationApply -Arguments @{ConfigurationData=$encodedMof;Force=$true} -Verbose -CimSession $session
        $session | Remove-CimSession
    }

    [bool] Test()
    {
        $error.clear()
        $session = New-CimSession -ComputerName $this.IPv6Address -Credential $this.Credential
        $result = Invoke-CimMethod -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager -MethodName TestConfiguration -Verbose -CimSession $session -ErrorAction SilentlyContinue
        $session | Remove-CimSession

        if ($error.Count -eq 0)
        {
            return $result.InDesiredState
        }
        else
        {
            return $false
        }
    }

    [IPv6NodeResource] Get()
    {
        return $this
    }
}
