Describe Invoke-ALTestRunner {
    InModuleScope ALTestRunner {
        Mock Get-ServerFromLaunchJson {'bc'}
        Mock Get-ValueFromAppJson {return [Guid]::NewGuid().Guid} -ParameterFilter {$KeyName -eq 'id'}
        Mock Get-ValueFromALTestRunnerConfig {'My Company'} {$KeyName -eq 'companyName'}
        Mock Set-ALTestRunnerConfigValue {}

        Context 'No test suite selected, container is running pre-15 version' {
            Mock Get-ALTestRunnerConfigPath {return Join-Path $TestDrive 'config.json'}
            Mock Get-ValueFromLaunchJson {}
            Mock Select-BCTestSuite {'DEFAULT'}
            Mock Get-ValueFromAppJson {}
            Mock Get-BCContainerNavVersion {return '14.5.0.0-W1'}
            Mock Invoke-RunTests {}

            It 'should prompt the user to enter the test suite' {
                Invoke-ALTestRunner -Tests All
                Assert-MockCalled Select-BCTestSuite                
            }
        }
    }
}