#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.Synopsis
   Deleta Snapshots com mais de X dias automaticamente
.DESCRIPTION
   Deleta Snapshot com mais de X dias e que não tenham uma string especifca na na descrição
.EXAMPLE
   
.EXAMPLE
   Inserir posteriormente
.CREATEDBY
    Juliano Alves de Brito Ribeiro (find me at julianoalvesbr@live.com or https://github.com/julianoabr or https://youtube.com/@powershellchannel)
.VERSION INFO
    0.1
.VERSION NOTES
    
.VERY IMPORTANT
    “Todos os livros científicos passam por constantes atualizações. 
    Se a Bíblia, que por muitos é considerada obsoleta e irrelevante, 
    nunca precisou ser atualizada quanto ao seu conteúdo original, 
    o que podemos dizer dos livros científicos de nossa ciência?” 

#>
Clear-Host

#Validate if VMware.VimAutomation.Core Module is installed
############################################################################################################################

$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Output "The Module Vmware.VimAutomation.Core is already loaded"
    
}#if validate module
else{
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop
    
}#else validate module

############################################################################################################################

#PAUSE POWERSHELL
function Pause-PSScript
{

   Read-Host 'Press Enter to continue…' | Out-Null
}


 function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric


#FUNCTION CONNECT TO VCENTER
function Connect-TovCenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Manual','Automatic')]
        $methodToConnect = 'Automatic',
        
                      
        [Parameter(Mandatory=$false,
                   Position=1)]
        [System.String[]]$vCServerList, 
                
       
        [Parameter(Mandatory=$false,
                   Position=2)]
        [ValidateSet('80','443')]
        [System.String]$port = '443',

        [Parameter(Mandatory=$false,
                   Position=3)]
        [System.String]$userName = 'Administrator@vsphere.local'

    )

    $vCenterPWD = (Get-content "$env:SystemDrive:\Temp\ENCRYPTED\vCAdmLocal-EncryptPWD.txt") | ConvertTo-SecureString

    $vCenterCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $userName,$vCenterPWD
           

    if ($methodToConnect -like 'Automatic'){
        
        foreach ($vCServer in $vCServerList){
        
            $Script:workingServer = $vCServer

            $vCentersConnected = $global:DefaultVIServers.Count

            if ($vCentersConnected -eq 0){
            
                Write-Host "You are not connected to any vCenter Server" -ForegroundColor DarkGreen -BackgroundColor White
            
            }#validate connected vCenters
            else{
            
                Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            
            }#validate connected vCenters
                     
        
        }#end of Foreach

    }#end of If Method to Connect
    else{
        
        $vCentersConnected = $global:DefaultVIServers.Count

        if ($vCentersConnected -eq 0){
            
            Write-Host "You are not connected to any vCenter" -ForegroundColor DarkGreen -BackgroundColor White
            
        }#validate connected vCenters
        else{
            
            Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            
         }#validate connected vCenters
        
        $workingLocationNum = ""
        
        $tmpWorkingLocationNum = ""
        
        $Script:WorkingServer = ""
        
        $i = 0

        #MENU SELECT VCENTER
        foreach ($vCServer in $vCServerList){
	   
                $vcServerValue = $vCServer
	    
                Write-Output "            [$i].- $vcServerValue ";	
	            $i++	
                }#end foreach	
                Write-Output "            [$i].- Exit this script ";

                while(!(isNumeric($tmpWorkingLocationNum)) ){
	                $tmpWorkingLocationNum = Read-Host "Type vCenter Number that you want to connect"
                }#end of while

                    $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($i-1))  ){
	                $Script:WorkingServer = $vcServers[$WorkingLocationNum]
                }
                else{
            
                    Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

       
      
    }#end of Else Method to Connect

    foreach ($vCServer in $vCServerList){

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Stop -Credential $vCenterCred
     
        Write-Host "You are connected to vCenter: $Script:WorkingServer" -ForegroundColor White -BackGroundColor DarkMagenta

     }

}#End of Function Connect to Vcenter


function Remove-SnapshotAuto
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.DateTime]$trimDate,

        # Param2 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateSet('DNRTeste','DNR3','DNR4','DNR5','DNR6','DNR10')]
        [System.String]$doNotRemoveString = 'DNRTeste'


       )

if ($trimDate -eq $null){

switch ($doNotRemoveString)
{
    'DNR3' {
    
        [System.DateTime]$trimDate = (Get-Date).AddHours(-72)
    
    }
    'DNR4' {
    
        [System.DateTime]$trimDate = (Get-Date).AddHours(-96)
    
    }
    'DNR5' {
    
        [System.DateTime]$trimDate = (Get-Date).AddHours(-120)
    
    }
    'DNR6' {
    
        [System.DateTime]$trimDate = (Get-Date).AddHours(-144)
    
    }
    'DNR10' {
    
        [System.DateTime]$trimDate = (Get-Date).AddHours(-240)
    
    }
    'DNRTeste' {
    
        [System.DateTime]$trimDate = (Get-Date).AddMinutes(-2)
    
    }

    
}#end of Switch


}#end of IF
else{

    Write-Host "I will remove snaphot older than: $trimDate" -ForegroundColor White -BackgroundColor Red

}#End of Else


[System.String]$numberOfDays = $doNotRemoveString.Substring(3,1)

$snapshotList = Get-Vm -Server $Script:WorkingServer | Get-Snapshot | Where-Object -FilterScript {$_.Created -lt "$trimdate" -and $_.Description -notlike "*$doNotRemoveString*"}

    if(!($snapshotList)){
    
        Write-Output "In Date: $currentDate there are no snapshots to remove according to parameters: $numberOfDays days ago and $stringDNR string in description field" | Out-File -FilePath $outputFile -Append

    }#end of IF
    else{
    
        Write-Output "Snapshots Deleted on: $fileDate" | Out-File -FilePath $outputFile -Append
    
        Write-Output "`n"

        foreach ($snap in $snapshotList){
    
            [System.String]$snapName = $snap.Name
     
            [System.String]$vmName = $snap.VM.Name

            $vMObj = $snap.vm

            [System.Boolean]$mountedTools = $vMObj.ExtensionData.Runtime.ToolsInstallerMounted
     
            #Validate if VM has VmTools mounted
            If ($mountedTools){
     
                Write-Output "VM: $vmName has Vmtools mounted in it's CD/DVD DRIVE. I will unmount it before remove Snapshot"

                $vMObj | Dismount-Tools -Verbose
        
                Start-Sleep -Seconds 10 -Verbose  
     
            }#End of IF
     
            Write-Output "Now I will remove Snapshot with Name: $snapName of the VM $vmName ..." 
       
            $snap | Select-Object -Property VM,VMId,PowerState,Name,Description,Created,SizeGB | Out-File -FilePath $outputFile -Append

            Get-VM -Name $vmName | 
            Get-Snapshot -Name $snapName |
            Remove-Snapshot -RunAsync -RemoveChildren -Confirm:$false -Verbose

        }#end forEach

        Start-Sleep -Seconds 60

        #LISTA DE VMs para verificar se é necessário consolidar discos.
        
        $vmList = @()
        
        $vmList = $snapshotList.VM.Name

        #IF NECESSARY CONSOLIDATE DISKS
        foreach ($tmpVM in $vmList){
    
            $vm = Get-VM -Name $tmpvm

            $consolidationNeeded = $vm.ExtensionData.Runtime.ConsolidationNeeded

            if ($consolidationNeeded -like 'False'){ 
        
                Write-Output "The VM $tmpVM does not need consolidation disk"  | Out-File -FilePath $outputFile -Append 

            }#end of IF
            else{
         
                Write-Output "The VM $tmpVM needs consolidation disk"  | Out-File -FilePath $outputFile -Append

                $vm.ExtensionData.ConsolidateVMDisks()
                 
            }#end of Else
    
        }#end forEach

    }#end of Else

}#End of Function



############################################################################################################################
#MAIN VARIABLES

$folderName = 'Daily-Report-Snapshot'  

#Date and Cut Date

$currentDate = (Get-Date -Format "ddMMyyyy-HHmm").ToString()

$fileDate = (Get-date).ToString()

#$dateToDisregard = (Get-Date).AddHours(-144)

#USE FOR TEST
#$dateToDisregard = (Get-Date).AddMinutes(-1)

#[System.String]$DNRString = 'DNR6'

$vcNameList = @()

#place data according to your environment
$vcNameList = ('vCenter1','vCenter2')

#USE FOR TEST
#$vcNameList = ('vCenter3','vCenter4')

############################################################################################################################

$Script_Parent = Split-Path -Parent $MyInvocation.MyCommand.Definition


#Create Folder to Export Results
############################################################################################################################
$outputPathExists = Test-Path -Path "$Script_Parent\$folderName"

 if (!($outputPathExists)){

    Write-Host "Folder Named: $folderName does not exists. I will create it" -ForegroundColor Yellow -BackgroundColor Black

    New-Item -Path $Script_Parent -ItemType Directory -Name $folderName -Confirm:$false -Verbose -Force

}
else{

    Write-Host "Folder Named: $folderName already exists" -ForegroundColor White -BackgroundColor Blue
            
    Write-Output "`n"
 
}#END OF ELSE

#File Output
$Script:outputFile = ($Script_Parent + "\$($folderName)\RemoveSnapshots_VMwareTeam_$($currentDate)_VC.txt") 


foreach ($vcName in $vcNameList)
{
    
    Connect-ToVcenterServer -methodToConnect Automatic -vCServerList $vcName -port 443

    Remove-SnapshotAuto -doNotRemoveString DNR5

    Disconnect-ViServer -Server $script:WorkingServer -Force -Confirm:$false -ErrorAction SilentlyContinue

    
}
