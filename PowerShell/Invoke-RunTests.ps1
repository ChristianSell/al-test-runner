function Invoke-RunTests {
    Param(
        [Parameter(Mandatory=$true)]
        $ContainerName,
        [Parameter(Mandatory=$true)]
        $CompanyName,
        [Parameter(Mandatory=$false)]
        [pscredential]$Credential,
        [Parameter(Mandatory=$true)]
        [Guid]$ExtensionId,
        [Parameter(Mandatory=$false)]
        [ValidateSet('All,Codeunit,Test')]
        [string]$Tests = 'All',
        [Parameter(Mandatory=$false)]
        [string]$TestCodeunit = '',
        [Parameter(Mandatory=$false)]
        [string]$TestFunction = '',
        [Parameter(Mandatory=$false)]
        [string]$TestSuiteName = ''
    )

    $ResultId = [Guid]::NewGuid().Guid + ".xml"
    $ResultFile = Join-Path (Split-Path (Get-ALTestRunnerConfigPath) -Parent) $ResultId
    $LastResultFile = Join-Path (Split-Path (Get-ALTestRunnerConfigPath) -Parent) 'last.xml'
    $ContainerResultFile = Join-Path (Get-ContainerResultPath) $ResultId
    
    $Message = "Running tests on $ContainerName, company $CompanyName"

    $Params = @{
        containerName = $ContainerName
        companyName = $CompanyName 
        XUnitResultFileName = $ContainerResultFile
    }
    
    if ($null -ne $Credential) {
        $Params.Add('credential', $Credential)
    }
    
    if ($TestCodeunit -ne '') {
        $Params.Add('testCodeunit', $TestCodeunit)
        $Message += ", codeunit $TestCodeunit"
    }
    
    if ($TestFunction -ne '') {
        $Params.Add('testFunction', $TestFunction)
        $Message += ", function $TestFunction"
    }
    
    if ($TestSuiteName -ne '') {
        $Params.Add('testSuite', $TestSuiteName)
        $Message += ", suite $TestSuiteName"
    }
    else {
        $Params.Add('extensionId', $ExtensionId)
        $Message += ", extension {0}" -f (Get-ValueFromAppJson -KeyName name)
    }

    [int]$AttemptNo = 1
    [bool]$BreakTestLoop = $false
    
    while(!$BreakTestLoop) {
        try {
            Write-Host $Message -ForegroundColor Green
            Run-TestsInBCContainer @Params -detailed -Verbose
            
            if (Test-Path $ContainerResultFile) {
                Copy-FileFromBCContainer -containerName $ContainerName -containerPath $ContainerResultFile -localPath $LastResultFile
                Copy-FileFromBCContainer -containerName $ContainerName -containerPath $ContainerResultFile -localPath $ResultFile
                Merge-ALTestRunnerTestResults -ResultsFile $ResultFile -ToPath (Join-Path (Split-Path (Get-ALTestRunnerConfigPath) -Parent) 'Results')
                Remove-Item $ResultFile
                Remove-Item $ContainerResultFile
                $BreakTestLoop = $true
            }
            else {
                throw 'Tests have not been run'
            }
        }
        catch {
            $AttemptNo++            
            Write-Host "Error occurred, retrying..." -ForegroundColor Magenta

            if ($AttemptNo -ge 3) {
                $BreakTestLoop = $true
            }
        }
    }
}

Export-ModuleMember -Function Invoke-RunTests