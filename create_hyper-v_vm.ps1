


function Check-IsElevated {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object System.Security.Principal.WindowsPrincipal($id)
  if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output $true
  }
  else {
    Write-Output $false
  }
}





# Define the function to create hyper-v vm from wsl vhdx
function Create_HyperV_VM_From_WSL_VHDX {

    ################################################
    # Preperation to create hyper-v vm
    ################################################

    Import-Module Hyper-V

    ################################################
    # Set VM parameters
    ################################################

    do {

        # Prompt the user to provide a name for the VM
        $vmName = Read-Host "`n Enter the name for the VM you want to provision "

        if ($vmName -ne "") {

            break
            
        }
        else {

            # Invalid input, display an error message and repeat the loop
            Write-Host "`n [:::Warning:::] You have not given a name for the VM. " -ForegroundColor White -BackgroundColor DarkRed

        }
    }
    while ($true)

    
    do {

        # Prompt the user to enter the amount of RAM/Memory you want to provision in GB for the VM
        $vmMemoryStartupBytes = Read-Host "`n Enter the amount of RAM/Memory you want to provision in GB. Please include GB in your input (e.g. 2GB). "

        if ($vmMemoryStartupBytes -ne "") {

            break
            
        }
        else {

            # Invalid input, display an error message and repeat the loop
            Write-Host "`n [:::Warning:::] You have not given the amount of RAM/Memory you want to provision in GB for the VM. Please include GB in your input (e.g. 2GB). " -ForegroundColor White -BackgroundColor DarkRed

        }
    }
    while ($true)

    
    do {

        # Prompt the user to enter the number of Virtual Processor you want to provision for the VM
        $vmProcessorCount = Read-Host "`n Enter the number of Virtual Processor you want to provision "

        if ($vmProcessorCount -ne "") {

            break
            
        }
        else {

            # Invalid input, display an error message and repeat the loop
            Write-Host "`n [:::Warning:::] You have not given the number of Virtual Processor you want to provision for the VM. " -ForegroundColor White -BackgroundColor DarkRed

        }
    }
    while ($true)



    $default_VM_SwitchName1 = "Default Switch"

    $vmSwitchName1 = Read-Host -Prompt "`n Enter the network adapter you want to connect for this VM or press `"Enter`" to use the default network adapter ( $default_VM_SwitchName1 ) "

    if ($vmSwitchName1 -eq "") {

        $vmSwitchName1 = $default_VM_SwitchName1
        
    }

    # Define the default path and Smart Paging File Loaction where the vm will be stored
    $defaultVMLocation = "C:\virtual-machines-storage\$vmName"

    # Prompt user to enter the path where the vm will be stored
    $vmLocation = Read-Host -Prompt "`n Enter the path where you want to store the VM or press `"Enter`" to use the default path ( $defaultVMLocation )"

    if ($vmLocation -eq "") {

        $vmLocation = $defaultVMLocation

    }

    $smartPagingFilePath = $vmLocation

    Write-Host "`n [:::Information:::] The VM will be stored at: `"$vmLocation`" " -ForegroundColor Blue -BackgroundColor Black 

    # Create the VM directory if it doesn't exist
    if (!(Test-Path -Path $vmLocation)) {

        New-Item -ItemType Directory -Confirm -Path $vmLocation
        
    }

    # Prompt user if user want to use existing VHDX or create new VHDX for the VM
    $VHDXPath = Read-Host -Prompt "`n Enter the path where your existing VHDX is stored or press `"Enter`" if you want to create a new VHDX "

    if ($VHDXPath -ne "") {
            
        # Copy the existing vhdx file to $vmLocation folder
        Copy-Item -Confirm -Verbose $VHDXPath $vmLocation

        $NewvhdxFilePath = (Get-ChildItem -Path $vmLocation -Filter "*.vhdx*").FullName

    } else {

        # Specify the path for the new VHDX file
        $VHDXPath = "$vmLocation\$vmName.vhdx"

        # Prompt user if user want to specify the size of VHDX in GB
        $VHDXSizeGB = Read-Host -Prompt "`n Enter the size of VHDX in GB. Please include GB in your input (e.g. 20GB). "

        # Create a new VHDX file
        # New-VHD -Path $VHDXPath -SizeBytes ($VHDXSizeGB * 1GB) -Fixed
        New-VHD -Path $VHDXPath -SizeBytes $VHDXSizeGB -Fixed

        $NewvhdxFilePath = (Get-ChildItem -Path $vmLocation -Filter "*$vmName*").FullName

    }

    # Create the VM
    New-VM -Name $vmName -MemoryStartupBytes $vmMemoryStartupBytes -Generation 2 -Path $vmLocation -VHDPath $NewvhdxFilePath

    ################################################
    # Configure the VM
    ################################################

    Set-VMProcessor -VMName $vmName -Count $vmProcessorCount

    # Disable Dynamic Memory
    Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false

    ################################################
    # Add network adapters
    ################################################

    Connect-VMNetworkAdapter -VMName $vmName -SwitchName $vmSwitchName1

    $default_VM_SwitchName2 = ""

    $vmSwitchName2 = Read-Host -Prompt "`n Enter the network adapter if there is additional network adapter you want to connect for this VM. If not, then leave it blank by pressing `"Enter`" "

    if ($vmSwitchName2 -eq "") {

        $vmSwitchName2 = $default_VM_SwitchName2
        
    } else {

        Add-VMNetworkAdapter -VMName $vmName -SwitchName $vmSwitchName2

    }

    # Enable Secure Boot
    Set-VMFirmware -VMName $vmName -EnableSecureBoot On

    # Configure SmartPagingFilePath for the vm
    Set-VM -Name $vmName -SmartPagingFilePath $smartPagingFilePath
    $vmStatus1 = $?

    # Configure CheckpointSnapshotFileLocation for the vm
    Set-VM -Name $vmName -CheckpointType Production -SnapshotFileLocation $vmLocation
    $vmStatus2 = $?

    # Clean-up
    if ($vmStatus1 -and $vmStatus2) {
            
        Write-Host "`n [:::Information:::] `"$vmName`" has been created and configured." -ForegroundColor Blue -BackgroundColor Black

    } else {

        Write-Host "`n [:::Warning:::] The SmartPagingFilePath or Checkpoint-SnapshotFileLocation for `"$vmName`" was not configure correctly." -ForegroundColor White -BackgroundColor DarkRed

    }

}





if (Check-IsElevated) {

    Create_HyperV_VM_From_WSL_VHDX

}
else {

  # prompt the user to use elevated powershell and exit the script
  Write-Host "`n [:::Warning:::] Please run this script as Administrator.`n" -ForegroundColor Blue -BackgroundColor Black

  exit

}

