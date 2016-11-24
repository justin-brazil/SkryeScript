#####################SCRIPT_CONTROLS##
#!#Name:   
#!#Author: 
#!#Description:  
#!#Tags: 
#!#Type:   
#!#Product:  PowerShell
#!#Notes:   
#!#Link:    
#!#Group:  
#!#Special: 
####################/SCRIPT_CONTROLS##


<#------------------------------------------------------------------    
 OUTLINE:    
     
 TO-DO:    

 NOTES:                                                          
--------------------------------------------------------------------#>
<#



#>
                                                #region Initialize-Script Built-In Functions                                                                                           
    ############################                                                                                          
 ####                          #####################################################################################
    #    INITIALIZE-SCRIPT     #  Functions:  INITIALIZE-LOGFILE, RECORD-EVENT, POPUP-NOTIFICATION
    ############################  Initializes project directory, event handling, and logfiles


function global:Initialize-Script
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
	
	.NOTES
		Additional information about the function.  #>
	
	##########     Script Variables    ############          
	
	$global:PROJECT_NAME = "MyScript"
	$global:PROJECT_ROOT_DIRECTORY = 'C:\PowerShell'
	$global:PROJECT_FOLDER = "$PROJECT_ROOT_DIRECTORY\$PROJECT_NAME"
	$global:PROJECT_DIRECTORY_LOGS = "$global:PROJECT_ROOT_DIRECTORY\Logs"
	$global:PROJECT_DIRECTORY_RESULTS = "$global:PROJECT_ROOT_DIRECTORY\Logs"
	$global:PROJECT_DIRECTORY_RESULTFILE = "$global:PROJECT_DIRECTORY_LOGS\$PROJECT_NAME Results $PROJECT_DATESTAMP.txt"
	$global:PROJECT_DATESTAMP = Get-Date -Format "MM-dd-yy hh.mmtt"
	$global:PROJECT_LOG_FILE = "$global:PROJECT_DIRECTORY_LOGS\$PROJECT_NAME Logs $PROJECT_DATESTAMP.txt"
	$global:PROJECT_EVENT_REGISTRY = @()
	
	function global:INITIALIZE-LOGFILE
	{<#		
	.SYNOPSIS
		Creates a project logfile
	
	.DESCRIPTION
		Creates a project logfile using the "Universal Script Variables."
		
		Utilization of this function ensures that log files are located and named in a consistent manner across all scripts. 
	
	.NOTES
		Additional information about the function. #>
	
		if (Test-Path $PROJECT_LOG_FILE)
		{
			$global:INITIALIZATION_EVENTS += "Log file already present"
		}
		else
		{
			New-Item $PROJECT_LOG_FILE -Type File -Force
			$global:INITIALIZATION_EVENTS += "Created logfile $PROJECT_LOG_FILE"
		}
		
		Add-Content $PROJECT_LOG_FILE "=============================================="
		Add-Content $PROJECT_LOG_FILE "$PROJECT_NAME INITIALIZATION"
		Add-Content $PROJECT_LOG_FILE "=============================================="
		Add-Content $PROJECT_LOG_FILE $PROJECT_DATESTAMP.ToString()
	}
	


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
			[String]$Source = $global:PROJECT_NAME
		)
		
		$POPUP = New-Object -ComObject Wscript.Shell
		$POPUP.Popup("$($MESSAGE)", 0, "$SOURCE", 0x1) > $NULL
	}
	
	
	function global:RECORD-EVENT
	{<#
	.SYNOPSIS
		Universal event handler designed to handle all logging, notification, errors, warnings, and user notifications.
	
	.DESCRIPTION
		Universal event handler designed to handle all logging, notification, errors, warnings, and user notifications.  Requires function POPUP-NOTIFICATION, defines function WRITE-LOG.
	
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
					   ValueFromPipeline = $true,
					   Position = 0,
					   HelpMessage = 'The message string to be displayed')]
			[ValidateNotNullOrEmpty()]
			[String]$Message,
			[Parameter(HelpMessage = 'Use to indicate end of section in logfile')]
			[switch]$SectionStart,
			[Parameter(HelpMessage = 'Use to indicate end of section in logfile')]
			[switch]$SectionEnd,
			[Parameter(HelpMessage = 'Send specified message to the log file')]
			[switch]$Log,
			[Parameter(HelpMessage = 'Appends status message to logfile.')]
			[switch]$Status,
			[Parameter(HelpMessage = 'Displays specified message to PowerShell console')]
			[switch]$Display,
			[Parameter(HelpMessage = 'Displays a pop-up notification to the user')]
			[switch]$Popup,
			[Parameter(HelpMessage = 'of your script.')]
			[switch]$TerminatingError,
			[Parameter(HelpMessage = 'Use to indicate a non-terminating error in the script.')]
			[switch]$Error,
			[Parameter(HelpMessage = 'Write a non-terminating warning to the console and log file.')]
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
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		}
		if ($SectionEnd)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "SectionEnd"
			$EVENT_REGISTRY.Message = $MESSAGE
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		}
		if ($Status)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "Status Message"
			$EVENT_REGISTRY.Message = $MESSAGE
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		}
		if ($Display)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "Display"
			$EVENT_REGISTRY.Message = $MESSAGE
			Write-Output $MESSAGE
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		}
		if ($Log)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "LogMessage"
			$EVENT_REGISTRY.Message = $MESSAGE
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		}
		if ($Popup)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "PopUp"
			$EVENT_REGISTRY.Message = $MESSAGE
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
			POPUP-NOTIFICATION -Message $MESSAGE -Source $global:PROJECT_NAME
		}
		if ($TerminatingError)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "TerminatingError"
			$EVENT_REGISTRY.Message = $MESSAGE
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
			POPUP-NOTIFICATION -Message $MESSAGE -Source "$global:PROJECT_NAME Terminating Error"
			Write-Error ('TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message + '  |  ' + $EVENT_REGISTRY.Timestamp)
			return
		}
		if ($Error)
		{
			$EVENT_REGISTRY.TimeStamp = Get-Date
			$EVENT_REGISTRY.Type = "Error"
			$EVENT_REGISTRY.Message = $MESSAGE
			$MESSAGES_ERROR += $MESSAGE
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
			Write-Warning ('TYPE: ' + $EVENT_REGISTRY.Type + '  |  ' + $EVENT_REGISTRY.Message + '  |  ' + $EVENT_REGISTRY.Timestamp)
			Write-Log -EVENT_REGISTRY $EVENT_REGISTRY
		}
		$global:PROJECT_EVENT_REGISTRY += $EVENT_REGISTRY
	}
	INITIALIZE-LOGFILE
} #/ INITIALIZE-SCRIPT
Initialize-Script                                                                              #endregion

                            
    ############################                                                                                          
 ####                          #####################################################################################
    #                          # 
    ############################  
                                                                    