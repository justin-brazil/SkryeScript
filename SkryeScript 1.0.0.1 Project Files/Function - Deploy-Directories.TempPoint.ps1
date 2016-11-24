#####################SCRIPT_CONTROLS##
#!#Name "FUNCTION - Deploy-Directories"
#!#Author "Justin Brazil"
#!#Description "Deploys standardized PoSH Directories to the root of C:\"
#!#Tags "Deploy,Directories,PoSH,PowerShell,Create,Structure,Local,Folders"
#!#Type "Function,Script,Code"
#!#Product "SkryeScript"
#!#Modes " "
#!#Notes "Creates C:\PowerShell structure"
#!#Link "\\qnap\scripting\PowerShell\Finished Scripts"
#!#Group " "
#!#Special "Universal"
####################/SCRIPT_CONTROLS##


Function global:Deploy-Directories {
$FOLDER_ROOT = 'C:\PowerShell\'

$FOLDER_SUBFOLDERS = @(
"AppData"
"Backups"
"Config"
"Logs"
"Results"
"Scheduling"
"Scripts"
"Temp"
"Variables"
)


Write-Host "#####################################" -ForegroundColor Cyan
Write-Host "    DEPLOY POWERSHELL DIRECTORIES    " -ForegroundColor Cyan
Write-Host "#####################################" -ForegroundColor Cyan


if (!(Test-Path -path $FOLDER_ROOT))
    {
        New-Item -ItemType Directory -Path $FOLDER_ROOT
        Write-Host "Created $FOLDER_ROOT Directory" -ForegroundColor Yellow
    }
else 
    {
        Write-Host "PowerShell Root Verified : $FOLDER_ROOT" -ForegroundColor Green
    }

ForEach ($SUBFOLDER in $FOLDER_SUBFOLDERS)

    {
    $TEMP_SUBFOLDER = ($FOLDER_ROOT + $SUBFOLDER)

    if (!(Test-Path $TEMP_SUBFOLDER))
        {
            New-Item -ItemType Directory $TEMP_SUBFOLDER
            Write-Host "Created $TEMP_SUBFOLDER" -ForegroundColor Yellow
        }
    else 
        {
            write-host "Verified $TEMP_SUBFOLDER is present" -ForegroundColor Green
        }
    }
}