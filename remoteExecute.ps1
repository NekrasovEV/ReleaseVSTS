param(
     [Parameter(Mandatory=$true)]
     [string] $Directory = $null,
     [Parameter(Mandatory=$true)]
     [string] $ScriptsDirectory = $null,
     [Parameter(Mandatory=$true)]
     [string] $BuildNumber = $null
     )
 
# Run your code that needs to be elevated here

    $ErrorActionPreference = 'Stop'
    
    trap
    {
        write-host "Errors found"
        write-host $_
        exit 1
    }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    $deploymentPath = [string]::Format("{0}", $Directory)
    $counter = 0
    
    Set-Location $deploymentPath
    
    $zipFiles = Get-ChildItem -Path $deploymentPath -Filter "*.zip"
    
    foreach($zipFile in $zipFiles)
    {
        if($zipFile.Name.Contains("DeployableRuntime"))
        {
            Write-Host "Unblocking File $($zipFile.name)..."
            Unblock-File -Path $zipFile.FullName
            Write-Host "Successful"
    
            Write-Host "Extracting..."
        
            $packageDirectory = [string]::Format("{0}\{1}_{2}", $deploymentPath, "package", $counter)
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile.FullName, $packageDirectory)
            Write-Host "Extracting $($zipFile.name) Finished"
    
            #Set topology data
            $defaultTopology = Join-Path $packageDirectory 'DefaultTopologyData.xml'
    
            [xml]$xml = Get-Content $defaultTopology
            $machine = $xml.TopologyData.MachineList.Machine
     
            ## Set computer name
            $machine.Name = $env:computername
     
            ##Set service models
            $serviceModelList = $machine.ServiceModelList
            $serviceModelList.RemoveAll()
     
            $instalInfoDll = Join-Path $packageDirectory 'Microsoft.Dynamics.AX.AXInstallationInfo.dll'
            [void][System.Reflection.Assembly]::LoadFile($instalInfoDll)
     
            $models = [Microsoft.Dynamics.AX.AXInstallationInfo.AXInstallationInfo]::GetInstalledServiceModel()
            foreach ($name in $models.Name)
            {
                $element = $xml.CreateElement('string')
                $element.InnerText = $name
                $serviceModelList.AppendChild($element)
            }
     
            $xml.Save($defaultTopology)
    
            #Generate Runbook
            $runbookFile = [string]::Format("{0}_{1}.xml", $BuildNumber, $counter)
            $runbookId = [string]::Format("{0}_{1}", $BuildNumber, $counter)
    
            write-host 'Generating Runbook...'
    
            $updateInstaller = Join-Path $packageDirectory 'AXUpdateInstaller.exe'
            #$updateInstaller = Join-Path 'C:\Users\Administrator\AppData\Roaming\Microsoft\Dynamics365Release\Packages\Packages' 'AXUpdateInstaller.exe'
    
            $serviceModelFile = Join-Path $packageDirectory 'DefaultServiceModelData.xml'
            & $updateInstaller generate "-runbookId=$runbookId" "-topologyFile=$defaultTopology" "-serviceModelFile=$serviceModelFile" "-runbookFile=$runbookFile"
    
            write-host "Runbook $($runbookFile) Generated"
            #Import Runbook
            write-host "Importing Runbook..."
        
            & $updateInstaller import "-runbookfile=$runbookFile"
    
            write-host "Runbook Imported"
    
            #Execute
            write-host "Executing..."
        
            & $updateInstaller execute "-runbookId=$runbookId"
    
            write-host "Deployment Complete"
    
            $counter = $counter + 1
        }
    }
    
    exit 0
    
    