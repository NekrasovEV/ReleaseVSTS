param(
     [Parameter(Mandatory=$true)]
     [string] $Directory = 'C:\Users\Administrator\AppData\Roaming\Microsoft\Dynamics365Release\Packages\Packages'
	 )
$date=$(Get-Date -Format dd.MM.yyyy);
$year=$(Get-Date -Format yy);
$month=$(Get-Date -Format MM);

Write-Host "##vso[task.setvariable variable=TodayDate]$date"
Write-Host "##vso[task.setvariable variable=Year]$year"
Write-Host "##vso[task.setvariable variable=Month]$month"

$deploymentPath = [string]::Format("{0}", $Directory)
$zipFiles = Get-ChildItem -Path $deploymentPath -Filter "*.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
    foreach($zipFile in $zipFiles)
    {
        if($zipFile.Name.Contains("DeployableRuntime"))
        {
#######################################################################
            # Write-Host "Unblocking File $($zipFile.name)..."
            # Unblock-File -Path $zipFile.FullName
            # Write-Host "Successful"
        
            # Write-Host "Extracting..."
            
            # $packageDirectory = [string]::Format("{0}\{1}_{2}", $deploymentPath, "package", $counter)
            # [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile.FullName, $packageDirectory)
            # Write-Host "Extracting $($zipFile.name) Finished"
#######################################################################
            $packageFile = $zipFile.Name;
            Write-Host "##vso[task.setvariable variable=PackageFile]$packageFile";
			$packageName = $packageFile.Trim(".zip");
            Write-Host "##vso[task.setvariable variable=PackageName]$packageName";
            $filePath = "C:\Users\Administrator\AppData\Roaming\Microsoft\Dynamics365Release\Packages\Packages\"+$zipFile.Name;
            $packageSizeBt = Get-ChildItem -File $filePath | select length
            $packageSize = $packageSizeBt.Length/1024/1000;
            Write-Host "##vso[task.setvariable variable=PackageSize]$packageSize";
			$platformBuild = $packageName.Trim("AXDeployableRuntime_");
            $platformBuildArray = $platformBuild.Split('_')
            $platformBuild = $platformBuildArray[0]
            Write-Host "##vso[task.setvariable variable=PlatformBuild]$platformBuild";

            #[xml]$HotfixInstallationInfoXml = Get-Content "$deploymentPath\$packageName\HotfixInstallationInfo.xml"
            
            [xml]$HotfixInstallationInfoXml = Get-Content "C:\Users\Administrator\AppData\Roaming\Microsoft\Dynamics365Release\Packages\Packages\package_0\HotfixInstallationInfo.xml"
            $HotfixInstallationInfo = $HotfixInstallationInfoXml.HotfixInstallationInfo
            $allComponentsList = $HotfixInstallationInfo.MetadataModuleList
            $allComponentsList
            $allCompListEnumerator = $allComponentsList.GetEnumerator()
            while ($allCompListEnumerator.MoveNext()) {
                $axModule = $allCompListEnumerator.Current
                $axModulesString += $axModule.InnerText + '; '
            }
            $platformVersion = $HotfixInstallationInfo.MetadataModuleRelease;
            Write-Host "##vso[task.setvariable variable=AllComponentsList]$axModulesString";
            Write-Host "##vso[task.setvariable variable=PlatformVersion]$platformVersion";
		}
    }