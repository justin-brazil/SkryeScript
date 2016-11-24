#####################SCRIPT_CONTROLS##
#!#Name "FUNCTION - Deploy-Directories"
#!#Author "Justin Brazil"
#!#Description "Deploys JustML standardized PoSH Directories to the root of C:\ for unversal consistency"
#!#Tags "Deploy,Directories,PoSH,PowerShell,Create,Structure,Local,Folders"
#!#Type "Function,Script,Code"
#!#Product "SkryeScript"
#!#Notes "Creates C:\PowerShell structure"
#!#Link "https://github.com/justin-brazil"
#!#Group "SkreyScript"
#!#Special 
####################/SCRIPT_CONTROLS##

<#
SkryeScript 
Copyright 2016 by Justin Brazil
Licensed under General Public License (GPL) V3 
Free to copy and distribute

GPL V3 LICENSE
----------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
	 but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

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