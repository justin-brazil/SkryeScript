#####################SCRIPT_CONTROLS##
#!#Name:   SkryeScript - Global Variables and Functions
#!#Author:  Justin Brazil    11/23/2016
#!#Description:  Global script variables and file definitions. Controls JustML header parsing functions and logging/alerting.
#!#Tags:   SkryeScript
#!#Type:   PowerShell
#!#Product:  SkryeScript
#!#Notes:   www.github.com/justin-brazil
#!#Link:     https://github.com/justin-brazil
#!#Group:    SkryeScript
#!#Special:   
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

#region My Functions

#region Logging and Alerting Functions

function global:POPUP-NOTIFICATION
{
	param
	(<#
		.SYNOPSIS
			Displays a pop-up notification to the user
		
		.DESCRIPTION
			Displays a dialog pop-up box designed to notify the user of an action
		
		.PARAMETER Message
			The message string to be displayed in the body of the pop-up notification
		
		.PARAMETER Source
			The provider/source of the message (displayed in the title bar of the pop-up)
        #>
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false,
				   Position = 0,
				   HelpMessage = 'The message string to be displayed in the body of the pop-up notification')]
		[ValidateNotNullOrEmpty()]
		[String]$Message,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false,
				   HelpMessage = 'The provider/source of the message (displayed in the title bar of the pop-up)')]
		[String]$Source = "SkryeScript Installer"
	)
	
	$POPUP = New-Object -ComObject Wscript.Shell
	$POPUP.Popup("$($MESSAGE)", 0, "$SOURCE", 0x1) > $NULL
}

Function global:Initialize-LogFile
{
	 <#
	.SYNOPSIS
		Universal logging, notification, results, and variables
	
	.DESCRIPTION
		Designed to handle initialization for all scripts.  Provides the following:
		  *  Initialize project directories
		  *  Create and name logfile
		  *  Create and name results output
		  *  Robust logging/event handling/notification functions
		
		FUNCTION:  INITIALIZE-SCRIPT
		  * Function: INTIALIZE-LOGFILE
		  * Function:  RECORD-EVENT
		  * Function: POPUP-ALERT
		  * Variable:  $PROJECT_LOG_FILE
		  * Variable:  $PROJECT_RESULT_FILE
	#>
	if (Test-Path $PROJECT_LOG_FILE)
	{
		$global:INITIALIZATION_EVENTS += "Log file already present"
	}
	else
	{
		New-Item $PROJECT_LOG_FILE -Type File
		$global:INITIALIZATION_EVENTS += "Created logfile $PROJECT_LOG_FILE"
		
	}
	
	Add-Content $PROJECT_LOG_FILE "=============================================="
	Add-Content $PROJECT_LOG_FILE "SKRYSCRIPT INITIALIZATION"
	Add-Content $PROJECT_LOG_FILE "=============================================="
	Add-Content $PROJECT_LOG_FILE $DATESTAMP_RUNTIME.ToString()
	
	if ($global:INITIALIZATION_EVENTS.Count -gt 0)
	{
		RECORD-EVENT -Log "Adding Initialization Messages to Logfile"
		
		ForEach ($INITIALIZATION_EVENT in $INITIALIZATION_EVENTS)
		{
			RECORD-EVENT -Log $INITIALIZATION_EVENT
		}
		
		RECORD-EVENT -Log "Completed:  Initialization Messages variable being retired, logging handed over to RECORD-EVENT"
		Remove-Variable INITIALIZATION_EVENTS -Scope Global
		
		
	} #/IF           
} #/INITIALIZE LOGFILE

function RECORD-EVENT
{
	<#
	.SYNOPSIS
		Universal event handler designed to handle all logging, notification, errors, warnings, and user notifications.
	
	.DESCRIPTION
		Universal event handler designed to handle all logging, notification, errors, warnings, and user notifications.  Requires function POPUP-NOTIFICATION, defines function WRITE-LOG.
			* TRACKS ALL STATUSES AND USER MESSAGES
			* HANDLES ALL EVENTS AND LOGGING
			* DEFINES FUNCTION: WRITE-LOG     
			* RELIES ON BUNDLED FUNCTION: POPUP-NOTIFICATION
	
	.PARAMETER Message
		The message string to be displayed
	
	.PARAMETER SectionStart
		Use to indicate the beginning of a section of the script.
		
		-Message should be the name of the section
		
		Writes to logfile and indicates when a section began.
	
	.PARAMETER SectionEnd
		Use to indicate the end of a section of the script.
		
		-Message should be the name of the section
		
		Writes to logfile and indicates when a section began.
	
	.PARAMETER Log
		Send specified message to the log file
	
	.PARAMETER Status
		Writes specified message to logfile as a STATUS message.
		
		Use for sending desired variable values and other indicators to logfile.
	
	.PARAMETER Display
		Displays specified message to PowerShell console, then writes to log file
	
	.PARAMETER Popup
		Pops up a Windows notification on the screen, then writes to log file.  Use to get the user's attention.
	
	.PARAMETER TerminatingError
		Use to notify the user of a terminating error and halt execution of your script.  
		
		Displays a pop-up notification, writes to console, and logs the error.  Terminates script when finished.
	
	.PARAMETER Error
		Use to indicate a non-terminating error in the script.
		
		Writes to console and logs to file.
	
	.PARAMETER Warning
		Write a non-terminating warning to the console and log file.
	
	.EXAMPLE
        In this example we use RECORD-EVENT to log operations related to a section of the script that scans folders for a list of files.  We indicate the beginning and end of the section, and notify the user of a warning that has occurred.  We write the files that were successfully parsed to the logfile.

        RECORD-EVENT "File Scan" -SectionStart
        RECORD-EVENT "Unable to verify selected directory" -Warning
        RECORD-EVENT "Successfully found $FILE.FullName" -Status
        RECORD-EVENT "File Scan" -SectionEnd	  #>	
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[String]$Message,
		[switch]$SectionStart,
		[switch]$SectionEnd,
		[switch]$Log,
		[switch]$Status,
		[switch]$Display,
		[switch]$Popup,
		[switch]$TerminatingError,
		[switch]$Error,
		[switch]$Warning
	)
	
	$EVENT_REGISTRY = New-Object -TypeName PSCustomObject
	$EVENT_REGISTRY | Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value Get-Date
	$EVENT_REGISTRY | Add-Member -MemberType NoteProperty -Name 'Type' -Value $NULL
	$EVENT_REGISTRY | Add-Member -MemberType NoteProperty -Name 'Message' -Value $NULL
	
	Function Write-Log ($EVENT_REGISTRY = $EVENT_REGISTRY)
	{
		Add-Content $PROJECT_LOG_FILE ($EVENT_REGISTRY.Timestamp.ToString() + '  |  TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message)
	}
	
	if ($SectionStart) #Message should be name of section
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "SectionStart"
		$EVENT_REGISTRY.Message = $MESSAGE
		
		#ACTION
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		
	}
	if ($SectionEnd)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "SectionEnd"
		$EVENT_REGISTRY.Message = $MESSAGE
		#ACTION
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
	}
	if ($Status)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "Status Message"
		$EVENT_REGISTRY.Message = $MESSAGE
		#ACTION
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
	}
	if ($Display)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "Display"
		$EVENT_REGISTRY.Message = $MESSAGE
		#ACTION
		Write-Output $MESSAGE
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
	}
	if ($Log)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "LogMessage"
		$EVENT_REGISTRY.Message = $MESSAGE
		#ACTION
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
	}
	if ($Popup)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "PopUp"
		$EVENT_REGISTRY.Message = $MESSAGE
		#ACTION
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		POPUP-NOTIFICATION -Message $MESSAGE -Source 'SKryeMS'
	}
	if ($TerminatingError)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "TerminatingError"
		$EVENT_REGISTRY.Message = $MESSAGE
		#ACTION  
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		POPUP-NOTIFICATION -Message $MESSAGE -Source 'SKryeMS Terminating Error'
		Write-Error ('TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message + '  |  ' + $EVENT_REGISTRY.Timestamp)
		return
	}
	if ($Error)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "Error"
		$EVENT_REGISTRY.Message = $MESSAGE
		$MESSAGES_ERROR += $MESSAGE
		#ACTION
		Write-Output ('TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message + '  |  ' + $EVENT_REGISTRY.Timestamp)
		Write-Error ('TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message + '  |  ' + $EVENT_REGISTRY.Timestamp)
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
	}
	if ($Warning)
	{
		$EVENT_REGISTRY.TimeStamp = Get-Date
		$EVENT_REGISTRY.Type = "Warning"
		$EVENT_REGISTRY.Message = $MESSAGE
		$MESSAGES_WARNING += $MESSAGE
		#ACTION
		Write-Warning ('TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message + '  |  ' + $EVENT_REGISTRY.Timestamp)
		Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
	}
	
	$global:GLOBAL_EVENT_REGISTRY += $EVENT_REGISTRY
}

#endregion

#region JustML Parsing and Filtering Functions

function Parse-JustMLHeaders
{
	 <#
	.SYNOPSIS
		Parses header data using JustML specification
	
	.DESCRIPTION
		Parses specified filetypes for header data according to syntax and delimiters of JustML markup language
		Includes detection mechanisms for malformed headers, missing headers, and validate headers
	
	.NOTES
		Additional information about the function.  
	#>
	[OutputType([array])]
	param
	(
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Specify an array of strings representng the paths to the files that will be indexed')]
		[Alias('Path')]
		[array]$Target_Folders,
		[Parameter(Mandatory = $false,
				   HelpMessage = 'Specify text file types')]
		[Alias('FileType')]
		[array]$Target_TextFileTypes
	)
	
	$Global:INDEXED_TEXTFILES = @()
	$Global:INDEXED_TEXTFILES_FAILURES = @()
	$global:LIST_TEXTFILES_FOUND = @()
	
	$global:TARGET_FOLDERS = Get-Content $global:DEFINITIONS_FOLDERS
	$global:TARGET_FILETYPES = Get-Content $global:DEFINITIONS_FILETYPES
	$global:TARGET_LOGFOLDERS = Get-Content $global:DEFINITIONS_LOGFOLDERS
	$global:TARGET_RESULTSFOLDERS = Get-Content $global:DEFINITIONS_REPORTFOLDERS
	
	ForEach ($TARGET_FOLDER in $global:TARGET_FOLDERS) #Enumerate items
	{
	$global:LIST_TEXTFILES_FOUND += Get-ChildItem $TARGET_FOLDER -Recurse -ErrorAction SilentlyContinue | Where { (($TARGET_TEXTFILETYPES -contains $_.Extension) -and ($_.PSIsContainer -eq $FALSE)) }
	}
	
	ForEach ($TARGET_FILE in $global:LIST_TEXTFILES_FOUND)
	{
		#DEFINE THE DELIMITERS USED FOR INDEXING THE HEADER DATA
		
		$DELIMITER_HEADER_START = '##SCRIPT_CONTROLS##'
		$DELIMITER_NAME = '#!#Name:'
		$DELIMITER_AUTHOR = '#!#Author:'
		$DELIMITER_DESCRIPTION = '#!#Description:'
		$DELIMITER_TAGS = '#!#Tags:'
		$DELIMITER_TYPE = '#!#Type:'
		$DELIMITER_PRODUCT = '#!#Product:'
		$DELIMITER_MODES = '#!#Modes:'
		$DELIMITER_NOTES = '#!#Notes:'
		$DELIMITER_LINK = '#!#Link:'
		$DELIMITER_GROUP = '#!#Group:'
		$DELIMITER_SPECIAL = '#!#Special:'
		$DELIMITER_HEADER_END = '##/SCRIPT_CONTROLS##'
				
		$INDEXED_OUTPUT_OBJECT = $NULL
		$INDEXED_OUTPUT_OBJECT = New-Object -TypeName PSCustomObject
		$INDEXED_OUTPUT_OBJECT | Add-Member –MemberType NoteProperty –Name FileName –Value $TARGET_FILE.Name
		$INDEXED_OUTPUT_OBJECT | Add-Member –MemberType NoteProperty –Name FileData –Value @()
		$INDEXED_OUTPUT_OBJECT | Add-Member –MemberType NoteProperty –Name HeaderData –Value @()
		$INDEXED_OUTPUT_OBJECT | Add-Member –MemberType NoteProperty –Name IndexData –Value @()
		$INDEXED_OUTPUT_OBJECT | Add-Member –MemberType NoteProperty –Name HeaderValidation –Value $NULL
		$INDEXED_OUTPUT_OBJECT | Add-Member –MemberType NoteProperty –Name IndexValidation –Value $NULL
		
		$FILE_DATA = $NULL
		$FILE_DATA = New-Object -TypeName PSCustomObject
		$FILE_DATA | Add-Member –MemberType NoteProperty –Name FileName –Value $TARGET_FILE.Name
		$FILE_DATA | Add-Member –MemberType NoteProperty –Name Directory –Value $TARGET_FILE.Directory
		$FILE_DATA | Add-Member –MemberType NoteProperty –Name FileType –Value $TARGET_FILE.Extension
		$FILE_DATA | Add-Member –MemberType NoteProperty –Name DateCreated –Value $TARGET_FILE.CreationTime
		$FILE_DATA | Add-Member –MemberType NoteProperty –Name DateModified –Value $TARGET_FILE.LastWriteTime
		
		$HEADER_DATA = $NULL
		$HEADER_DATA = New-Object -TypeName PSCustomObject
		$HEADER_DATA | Add-Member –MemberType NoteProperty –Name HeaderStart –Value $NULL
		$HEADER_DATA | Add-Member –MemberType NoteProperty –Name HeaderEnd –Value $NULL
		$HEADER_DATA | Add-Member –MemberType NoteProperty –Name HeaderData –Value @()
		$HEADER_DATA | Add-Member –MemberType NoteProperty –Name BodyStart –Value $NULL
		$HEADER_DATA | Add-Member –MemberType NoteProperty –Name HeaderValidation -Value @()
		$HEADER_DATA | Add-Member –MemberType NoteProperty –Name HeaderErrors –Value @()
		
		$FILE_RAW_CONTENTS = Get-Content $TARGET_FILE.FullName
	
		#PARSE THE HEADER CONTENTS LINE BY LINE TO FIND HEADER START, END, AND BODY

		$LINE_NUMBER = 0
		
		ForEach ($LINE in $FILE_RAW_CONTENTS)
		{
			if ($LINE -match $DELIMITER_HEADER_START)
			{
				$HEADER_DATA.HeaderStart = $LINE_NUMBER
			}
			if ($LINE -match $DELIMITER_HEADER_END)
			{
				$HEADER_DATA.HeaderEnd = $LINE_NUMBER
				$HEADER_DATA.BodyStart = ($LINE_NUMBER + 1)
				break
			}
			if (($HEADER_DATA.HeaderEnd -eq $NULL) -and ($HEADER_DATA.HeaderStart -ne $NULL))
			{
				if ($LINE_NUMBER -NE $HEADER_DATA.HeaderStart) { $HEADER_DATA.HeaderData += $LINE }
			}
			if ($LINE_NUMBER -gt 25)  #only reads the first 25 lines for header data
			{
				break
			}
			
			$LINE_NUMBER = $LINE_NUMBER + 1
		}
			
		#VALIDATE HEADER STRUCTURE
		
		if (($HEADER_DATA.HeaderStart -ne $NULL) -and ($HEADER_DATA.HeaderEnd -ne $NULL) -and ($HEADER_DATA.HeaderData.Count -gt 0))
		{
			RECORD-EVENT "Successfully parsed ($FILE_DATA.Filename)" -Log
			$HEADER_DATA.HeaderValidation = "Success"
		}
		if (($HEADER_DATA.HeaderStart -eq $NULL) -and ($HEADER_DATA.HeaderEnd -eq $NULL))
		{
			$HEADER_DATA.HeaderValidation = "Missing"
			$HEADER_DATA.HeaderErrors += "File does not contain header start or termination lines"
		}
		if ((($HEADER_DATA.HeaderStart -ne $NULL) -and ($HEADER_DATA.HeaderEnd -eq $NULL)))
		{
			$HEADER_DATA.HeaderValidation = "Malformed"
			$HEADER_DATA.HeaderErrors += "MALFORMED HEADER DETECTED : Header start detected but termination line is missing"
		}
		if ((($HEADER_DATA.HeaderStart -eq $NULL) -and ($HEADER_DATA.HeaderEnd -ne $NULL)))
		{
			$HEADER_DATA.HeaderValidation = "Malformed"
			$HEADER_DATA.HeaderErrors += "MALFORMED HEADER DETECTED : Missing Header start line, but termination line detected"
		}
		if (($HEADER_DATA.HeaderStart -ne $NULL) -and ($HEADER_DATA.HeaderEnd -ne $NULL) -and ($HEADER_DATA.HeaderData.Count -eq 0))
		{
			$HEADER_DATA.HeaderValidation = "Empty"
			$HEADER_DATA.HeaderErrors += "Detected header start and termination but no header content was found"
		}
		
		#PARSE THE HEADER DATA
		
		$INDEXED_DATA = $NULL
		
		if ($HEADER_DATA.HeaderValidation -eq 'Success')
		{
			$INDEXED_DATA = New-Object -TypeName PSCustomObject
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Name' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_NAME + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Author' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_AUTHOR + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Description' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_DESCRIPTION + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Tags' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_TAGS + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Type' -Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_TYPE + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Product' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_PRODUCT + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Modes' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_MODES + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Notes' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_NOTES + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Link' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_LINK + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Group' –Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_GROUP + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'Special' -Value ($HEADER_DATA.HeaderData | Where { $_ -like ($DELIMITER_SPECIAL + '*') } -ErrorAction SilentlyContinue)
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'SyntaxNotFound' –Value ($HEADER_DATA.HeaderData | Where { ($_ -notlike ($DELIMITER_NAME + '*')) -and ($_ -notlike ($DELIMITER_AUTHOR + '*')) -and ($_ -notlike ($DELIMITER_AUTHOR + '*')) -and ($_ -notlike ($DELIMITER_DESCRIPTION + '*')) -and ($_ -notlike ($DELIMITER_TAGS + '*')) -and ($_ -notlike ($DELIMITER_TYPE + '*')) -and ($_ -notlike ($DELIMITER_PRODUCT + '*')) -and ($_ -notlike ($DELIMITER_MODES + '*')) -and ($_ -notlike ($DELIMITER_NOTES + '*')) -and ($_ -notlike ($DELIMITER_LINK + '*')) -and ($_ -notlike ($DELIMITER_GROUP + '*')) -and ($_ -notlike ($DELIMITER_SPECIAL + '*')) }) -ErrorAction SilentlyContinue
			$INDEXED_DATA | Add-Member –MemberType NoteProperty –Name 'IndexErrors' –Value $NULL
			
			if ($INDEXED_DATA.Name -ne $NULL) { $INDEXED_DATA.Name = ($INDEXED_DATA.Name).Replace($DELIMITER_NAME, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd() }
			if ($INDEXED_DATA.Author -ne $NULL) { $INDEXED_DATA.Author = ($INDEXED_DATA.Author).Replace($DELIMITER_AUTHOR, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd() }
			if ($INDEXED_DATA.Description -ne $NULL) { $INDEXED_DATA.Description = ($INDEXED_DATA.Description).Replace($DELIMITER_DESCRIPTION, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd() }
			if ($INDEXED_DATA.Tags -ne $NULL) { $INDEXED_DATA.Tags = ($INDEXED_DATA.Tags).Replace($DELIMITER_TAGS, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			if ($INDEXED_DATA.Type -ne $NULL) { $INDEXED_DATA.Type = ($INDEXED_DATA.Type).Replace($DELIMITER_TYPE, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			if ($INDEXED_DATA.Product -ne $NULL) { $INDEXED_DATA.Product = ($INDEXED_DATA.Product).Replace($DELIMITER_PRODUCT, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			if ($INDEXED_DATA.Modes -ne $NULL) { $INDEXED_DATA.Modes = ($INDEXED_DATA.Modes).Replace($DELIMITER_MODES, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			if ($INDEXED_DATA.Notes -ne $NULL) { $INDEXED_DATA.Notes = ($INDEXED_DATA.Notes).Replace($DELIMITER_NOTES, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd() }
			if ($INDEXED_DATA.Link -ne $NULL) { $INDEXED_DATA.Link = ($INDEXED_DATA.Link).Replace($DELIMITER_LINK, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			if ($INDEXED_DATA.Group -ne $NULL) { $INDEXED_DATA.Group = ($INDEXED_DATA.Group).Replace($DELIMITER_GROUP, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			if ($INDEXED_DATA.Special -ne $NULL) { $INDEXED_DATA.Special = ($INDEXED_DATA.Special).Replace($DELIMITER_SPECIAL, '').Replace("'", "").Replace('"', "").TrimStart().TrimEnd().Split(',') }
			
			#SET VALIDATION FLAGS      
			
			$INDEXED_OUTPUT_OBJECT.HeaderValidation = $TRUE
			
			if ($INDEXED_DATA.SyntaxNotFound.Count -gt 0)
			{
				#IF2
				$INDEXED_DATA.IndexErrors = "WARNING: Unexpected data found in header: $INDEXED_DATA.SyntaxNotFound"
				$INDEXED_OUTPUT_OBJECT.IndexValidation = $FALSE
			} #/IF2 
			else
			{
				$INDEXED_OUTPUT_OBJECT.IndexValidation = $TRUE
			}
			
		} ##/IF 
		
		else
		{
			$INDEXED_OUTPUT_OBJECT.HeaderValidation = $FALSE
			$INDEXED_OUTPUT_OBJECT.IndexValidation = $FALSE
		}
		
		#ADD OBJECTS INTO $INDEXED_OUTPUT_OBJECT (PARENT OBJECT)
		
		$INDEXED_OUTPUT_OBJECT.FileData = $FILE_DATA
		$INDEXED_OUTPUT_OBJECT.HeaderData = $HEADER_DATA
		$INDEXED_OUTPUT_OBJECT.IndexData = $INDEXED_DATA
		
		#ADD TO GLOBAL VARIABLES    
		
		if ($INDEXED_OUTPUT_OBJECT.IndexValidation -eq $TRUE)
		{
			$Global:INDEXED_TEXTFILES += $INDEXED_OUTPUT_OBJECT
		}
		else
		{
			$Global:INDEXED_TEXTFILES_FAILURES += $INDEXED_OUTPUT_OBJECT
		}
		
	} #/FOREACH
	
	#RESULTS REPORT
	
	$global:RESULTS_FILES_FOUND_COUNT = ($global:LIST_TEXTFILES_FOUND.Count)
	$global:RESULTS_SUCCESS_COUNT = ($global:INDEXED_TEXTFILES.Count)
	$global:RESULTS_FAILURES_COUNT = ($global:INDEXED_TEXTFILES_FAILURES.Count)
	$global:RESULTS_HEADER_ERROR_COUNT = ($Global:INDEXED_TEXTFILES_FAILURES | Where { $_.HeaderValidation -ne $TRUE }).Count
	$global:RESULTS_SYNTAX_ERROR_COUNT = ($Global:INDEXED_TEXTFILES_FAILURES | Where { ($_.HeaderValidation -eq $TRUE) -and ($_.IndexValidation -ne $TRUE) }).Count
	
	#RESULTS SUMMARY
	
	if ($RESULTS_SUCCESS_COUNT -gt 0)
	{
		RECORD-EVENT "===============================" -Log
		RECORD-EVENT "SUCCESSFULLY PARSED AND INDEXED THE FOLLOWING TEXT-BASED FILES:" -Log
		RECORD-EVENT "$global:INDEXED_TEXTFILES.Filename" -Log
		RECORD-EVENT "===============================" -Log
	}
	
	if ($RESULTS_FAILURES_COUNT -gt 0)
	{
		RECORD-EVENT ("FAILED TO INDEX" + $RESULTS_FAILURES_COUNT + "Files") -Warning
		
		if ($RESULTS_HEADER_ERROR_COUNT -gt 0)
		{
			RECORD-EVENT "INVALID HEADERS DETECTED IN THE FOLLOWING TEXT-BASED FILES:" -Warning
			foreach ($FAILURE in ($Global:INDEXED_TEXTFILES_FAILURES | Where { $_.HeaderValidation -ne $TRUE }))
			{
				RECORD-EVENT "Invalid Header Data: $FAILURE.FileName" -Log
			}
		}
		if ($RESULTS_SYNTAX_ERROR_COUNT -gt 0)
		{
			RECORD-EVENT "HEADER SYNTAX ERRORS FOUND FOR THE FOLLOWING TEXT-BASED FILES:" -Warning
			foreach ($FAILURE in ($Global:INDEXED_TEXTFILES_FAILURES | Where { ($_.HeaderValidation -eq $TRUE) -and ($_.IndexValidation -ne $TRUE) }))
			{
				RECORD-EVENT "Malformed Header Data: $FAILURE.FileName" -Warning
			}
			
		}
	}
	
	#AGREGATES AND STATISTICS SUMMARY
	
	RECORD-EVENT "===============================" -Log
	RECORD-EVENT  "PARSE-HEADERS FUNCTION RESULTS:" -Log
	RECORD-EVENT  "===============================" -Log
	RECORD-EVENT  ("TOTAL FILES PARSED:   " + $RESULTS_FILES_FOUND_COUNT) -Log
	RECORD-EVENT  ("TOTAL SUCCESSES:   " + $RESULTS_SUCCESS_COUNT) -Log
	RECORD-EVENT  ("TOTAL FAILURES:   " + $RESULTS_FAILURES_COUNT) -Log
	
	if ($RESULTS_FAILURES_COUNT -gt 0)
	{
		RECORD-EVENT ("     INVALID HEADERS COUNT:   " + $RESULTS_HEADER_ERROR_COUNT) -Warning
		RECORD-EVENT ("     INVALID HEADER SYNTAX COUNT:   " + $RESULTS_SYNTAX_ERROR_COUNT) -Warning
		
	}
	$labelCount1.Text = ("Indexed Scripts : " + $INDEXED_TEXTFILES.Count)
	RECORD-EVENT "Parse-JustML" -SectionEnd
	return $INDEXED_TEXTFILES
}




function Apply-Filter
{
	<#
	.SYNOPSIS
		Filters available files by user selection
	
	.DESCRIPTION
		Parses index strings and extracts data from delimiters.
		Parses indexed header data for target textfiles for product, type, extension and group so that search logic can then be applied
	#>
	if ($global:TARGET_TAGS -ne $null) { $global:FILTERED_TEXTFILES = $global:MODE_FILES | where { $_.IndexData.Tags -contains $global:TARGET_TAGS } }
	else { $global:FILTERED_TEXTFILES = $global:MODE_FILES }
	
	#FILTERS
	#########
	
	if ($Global:FILTERED_TEXTFILES.IndexData.Product -ne $NULL)
	{
		[array]$global:FILTER_PRODUCT = ($Global:FILTERED_TEXTFILES.IndexData.Product | where { $_ -ne "" } | select-object -Unique).TrimStart().TrimEnd()
	}
	if ($Global:FILTERED_TEXTFILES.IndexData.Type -ne $NULL)
	{
		[array]$global:FILTER_TYPE = ($Global:FILTERED_TEXTFILES.IndexData.Type | where { $_ -ne "" } | select-object -Unique).TrimStart().TrimEnd()
	}
	if ($Global:FILTERED_TEXTFILES.FileData.Filetype -ne $NULL)
	{
		[array]$global:FILTER_EXTENSION = ($Global:FILTERED_TEXTFILES.FileData.Filetype | where { $_ -ne "" } | select-object -Unique).TrimStart().TrimEnd()
	}
	if ($Global:FILTERED_TEXTFILES.IndexData.Group -ne $NULL)
	{
		[array]$global:FILTER_GROUP = ($Global:FILTERED_TEXTFILES.IndexData.Group | where { $_ -ne "" } | select-object -Unique).TrimStart().TrimEnd()
	}
	
	if (($global:SELECTED_FILTERS).Count -gt 0)
	{
		$TEMP_PRODUCT = @()
		$TEMP_EXTENSION = @()
		$TEMP_TYPE = @()
		$TEMP_GROUP = @()
		
		#String handling for header index objects to eliminate delimiters
		foreach ($OBJECT in $global:SELECTED_FILTERS)
		{
			
			$OBJECT = $OBJECT.TrimStart().TrimEnd()
			if (($OBJECT.Split(' _#_ ')[-1] -eq 'Product') -and ($OBJECT.Split(' _#_ ')[0] -ne "")) { $TEMP_PRODUCT += $OBJECT.Split('_#_')[0].TrimStart().TrimEnd() }
			if (($OBJECT.Split(' _#_ ')[-1] -eq 'Extension') -and ($OBJECT.Split(' _#_ ')[0] -ne "")) { $TEMP_EXTENSION += $OBJECT.Split('_#_')[0].TrimStart().TrimEnd() }
			if (($OBJECT.Split(' _#_ ')[-1] -eq 'Type') -and ($OBJECT.Split(' _#_ ')[0] -ne "")) { $TEMP_TYPE += $OBJECT.Split('_#_')[0].TrimStart().TrimEnd() }
			if (($OBJECT.Split(' _#_ ')[-1] -eq 'Group') -and ($OBJECT.Split(' _#_ ')[0] -ne "")) { $TEMP_GROUP += $OBJECT.Split('_#_')[0].TrimStart().TrimEnd() }
		}
		
		#Match properties with text files
		if ($TEMP_PRODUCT.Count -gt 0)
		{
			foreach ($PRODUCT in $TEMP_PRODUCT)
			{
				$global:FILTERED_TEXTFILES = $global:FILTERED_TEXTFILES | where { (Compare-Object -ReferenceObject $PRODUCT -DifferenceObject $_.IndexData.Product.TrimStart().TrimEnd() -ExcludeDifferent -IncludeEqual).SideIndicator -contains '==' }
			}
		}
		if ($TEMP_EXTENSION.Count -gt 0)
		{
			foreach ($EXTENSION in $TEMP_EXTENSION)
			{
				$global:FILTERED_TEXTFILES = $global:FILTERED_TEXTFILES | where { (Compare-Object -ReferenceObject $EXTENSION -DifferenceObject $_.FileData.Filetype.TrimStart().TrimEnd() -ExcludeDifferent -IncludeEqual).SideIndicator -contains '==' }
			}
		}
		if ($TEMP_TYPE.Count -gt 0)
		{
			foreach ($TYPE in $TEMP_TYPE)
			{
				$global:FILTERED_TEXTFILES = $global:FILTERED_TEXTFILES | where { (Compare-Object -ReferenceObject $TYPE -DifferenceObject $_.IndexData.Type.TrimStart().TrimEnd() -ExcludeDifferent -IncludeEqual).SideIndicator -contains '==' }
			}
		}
		if ($TEMP_GROUP.Count -gt 0)
		{
			foreach ($_GROUP in $TEMP_GROUP)
			{
				$global:FILTERED_TEXTFILES = $global:FILTERED_TEXTFILES | where { (Compare-Object -ReferenceObject $_GROUP -DifferenceObject $_.IndexData.Group.TrimStart().TrimEnd() -ExcludeDifferent -IncludeEqual).SideIndicator -contains '==' }
			}
		}
	}
	#Calculate results statistics
	if (($global:FILTERED_TEXTFILES -ne $null) -and ($global:FILTERED_TEXTFILES.Count -eq $NULL)) { $global:Label_Counter = 1 }
	if (($global:FILTERED_TEXTFILES -ne $NULL) -and ($global:FILTERED_TEXTFILES.Count -ne $NULL)) { $global:Label_Counter = $global:FILTERED_TEXTFILES.Count }
	if ($global:FILTERED_TEXTFILES -eq $NULL) { $global:Label_Counter = 0 }
	$labelCount1.Text = ("Scripts in Library : " + $global:INDEXED_TEXTFILES.Count + '  |  Matches : ' + $global:Label_Counter)
}

#endregion

#region Built-In Functions

#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Written by Sapien and included for redistribution with PowerShell Studio 2016 (awesome product)
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($hostinvocation -ne $null)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory

#endregion

#region Global Variables and File Definitions

$global:INDEXED_TEXTFILES = @()
$global:TARGET_TAGS = $NULL
[System.Collections.ArrayList]$global:SELECTED_FILTERS = @()

$global:PROJECT_NAME = 'SkryeScript'
$global:PROJECT_FOLDER = Get-ScriptDirectory
$global:DATESTAMP_RUNTIME = Get-Date -Format yyyy-MM.dd-hh.mm

$global:DEFINITIONS_FOLDERS = ($global:PROJECT_FOLDER + '\SkryeScript_ScriptFolders.txt')
$global:DEFINITIONS_FILETYPES = ($global:PROJECT_FOLDER + '\SkryeScript_Filetypes.txt')
$global:DEFINITIONS_LOGFOLDERS = ($global:PROJECT_FOLDER + '\SkryeScript_LogFolders.txt')
$global:DEFINITIONS_REPORTFOLDERS = ($global:PROJECT_FOLDER + '\SkryeScript_ReportFolders.txt')
$global:DEFINITIONS_DEFAULTPROGRAM = ($global:PROJECT_FOLDER + '\SkryeScript_DefaultProgram.txt')
$global:DEFINITIONS_INSTRUCTIONS = ($global:PROJECT_FOLDER + '\SkryeScript Documentation.pdf')
$global:DEFINITIONS_SCRIPT_TEMPLATE = ($global:PROJECT_FOLDER + '\SkryeScript_script_Template.txt')
$global:DEFINITIONS_FUNCTION_TEMPLATE = ($global:PROJECT_FOLDER + '\SkryeScript_function_Template.txt')
$global:DEFINITIONS_FIRSTRUN = ($global:PROJECT_FOLDER + '\SkryeScript_FirstRun.txt')

$global:DEFINITIONS_TINYFOLDER1 = ($global:PROJECT_FOLDER + '\SkryeScript_TinyFolder1.txt')
$global:DEFINITIONS_TINYFOLDER2 = ($global:PROJECT_FOLDER + '\SkryeScript_TinyFolder2.txt')
$global:DEFINITIONS_TINYWEB1 = ($global:PROJECT_FOLDER + '\SkryeScript_TinyWeb1.txt')
$global:DEFINITIONS_TINYWEB2 = ($global:PROJECT_FOLDER + '\SkryeScript_TinyWeb2.txt')
$global:DEFINITIONS_TINYNOTE1 = ($global:PROJECT_FOLDER + '\SkryeScript_TinyNote1.txt')
$global:DEFINITIONS_TINYNOTE2 = ($global:PROJECT_FOLDER + '\SkryeScript_TinyNote2.txt')

Function global:LOAD-DEFINITIONS {
$global:TARGET_FOLDERS = Get-Content $global:DEFINITIONS_FOLDERS
$global:TARGET_FILETYPES = Get-Content $global:DEFINITIONS_FILETYPES
$global:TARGET_LOGFOLDERS = Get-Content $global:DEFINITIONS_LOGFOLDERS
$global:TARGET_RESULTSFOLDERS = Get-Content $global:DEFINITIONS_REPORTFOLDERS
$global:TARGET_PROGRAM = Get-Content $global:DEFINITIONS_DEFAULTPROGRAM
	
$global:TARGET_SCRIPT_TEMPLATE = Get-Content $global:DEFINITIONS_SCRIPT_TEMPLATE
	#if ($global:TARGET_SCRIPT_TEMPLATE -like "$global*"){ $global:TARGET_SCRIPT_TEMPLATE = Invoke-Expression  $global:TARGET_SCRIPT_TEMPLATE} #Expand variable if present
$global:TARGET_FUNCTION_TEMPLATE = Get-Content $global:DEFINITIONS_FUNCTION_TEMPLATE
	#if ($global:TARGET_FUNCTION_TEMPLATE -like "$global*") { $global:TARGET_FUNCTION_TEMPLATE = Invoke-Expression  $global:TARGET_FUNCTION_TEMPLATE } #Expand variable if present
	
$global:TARGET_TINYFOLDER1 = Get-Content $global:DEFINITIONS_TINYFOLDER1
$global:TARGET_TINYFOLDER2 = Get-Content $global:DEFINITIONS_TINYFOLDER2
$global:TARGET_TINYWEB1 = Get-Content $global:DEFINITIONS_TINYWEB1
$global:TARGET_TINYWEB2 = Get-Content $global:DEFINITIONS_TINYWEB2
}

global:LOAD-DEFINITIONS

$global:PROJECT_DATESTAMP = Get-Date -Format "MM-dd-yy hh.mmtt"

$global:PROJECT_LOG_FILE = "$global:TARGET_LOGFOLDERS\$global:PROJECT_NAME Logs $PROJECT_DATESTAMP.txt"
$global:PROJECT_RESULTS_FILE = "$global:TARGET_RESULTSFOLDERS\$global:PROJECT_NAME Results $PROJECT_DATESTAMP.txt"


$global:TARGET_TINYNOTE1 = $global:DEFINITIONS_TINYNOTE1
$global:TARGET_TINYNOTE2 = $global:DEFINITIONS_TINYNOTE2

$global:FLAG_MODE = 'Scripts'
$global:MODE_FILES = @()
$global:LOG_FILES = @()
$global:RESULT_FILES = @()
$global:FLAG_INIT_DATATABLE = $true

$global:DATESTAMP_RUNTIME = Get-Date -Format yyyy-MM.dd-hh.mm

$global:GLOBAL_EVENT_REGISTRY = @()

#INITIALIZATION LOGIC
if ($global:TARGET_FUNCTION_TEMPLATE -contains "C:\Change\Me.ps1")
{
	$global:TARGET_FUNCTION_TEMPLATE = ($global:PROJECT_FOLDER + '\Template - New Function.ps1')
}
if ($global:TARGET_SCRIPT_TEMPLATE -contains "C:\Change\Me.ps1")
{
	$global:TARGET_SCRIPT_TEMPLATE  = ($global:PROJECT_FOLDER + '\Template - New Script.ps1')
}

#endregion