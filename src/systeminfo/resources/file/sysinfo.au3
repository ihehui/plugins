#include <ProgressConstants.au3>
#include <WindowsConstants.au3>
#include <Process.au3>



#AutoIt3Wrapper_icon=D:\AutoIt_Working\resource\pic\xp.ico
#AutoIt3Wrapper_Res_Comment=System information Collector For Sitoy
#AutoIt3Wrapper_Res_Description=System information Collector
#AutoIt3Wrapper_Res_Fileversion=2011.9.30.1
#AutoIt3Wrapper_Res_LegalCopyright=贺辉

#NoTrayIcon

Global $MyError = ObjEvent("AutoIt.Error", "MyErrFunc") ; Install a custom error handler

; This is my custom error handler
Func MyErrFunc()

	Local $MyRet[5]
	$MyRet[0] = $MyError.number
	$MyRet[1] = Hex($MyRet[0], 8)
	$MyRet[2] = $MyError.scriptline
	$MyRet[3] = $MyError.description
	$MyRet[4] = $MyError.source

	ConsoleWrite("COM Error! " & _
			"Number: " & $MyRet[1] & _
			"ScriptLine: " & $MyRet[2] & _
			"Description:" & $MyRet[3] & _
			"Source:" & $MyRet[4] & @CRLF)


	MsgBox(16, "COM Error!", @CRLF & "We intercepted a  Error !" & @CRLF & @CRLF & _
			"Description:" & @TAB & $MyRet[3] & @CRLF & _
			"Source:	" & @TAB & $MyRet[4] & @CRLF & _
			"Script Line:" & @TAB & $MyRet[2] & @CRLF & _
			"Number:	" & @TAB & $MyRet[1] & @CRLF & @CRLF)

	;Msgbox(0,"AutoIt COM Error","We intercepted a  Error !"&@CRLF&@CRLF & _
	;     "err.description is: " &@TAB&$MyError.description&@CRLF& _
	;    "err.windescription:"  &@TAB&$MyError.windescription&@CRLF& _
	;    "err.number is: "      &@TAB&hex($MyError.number,8)&@CRLF& _
	;    "err.lastdllerror is: "&@TAB&$MyError.lastdllerror&@CRLF& _
	;    "err.scriptline is: "  &@TAB&$MyError.scriptline& @CRLF& _
	;     "err.source is: "      &@TAB&$MyError.source&@CRLF& _
	;     "err.helpfile is: "    &@TAB&$MyError.helpfile&@CRLF& _
	;     "err.helpcontext is: " &@TAB&$MyError.helpcontext)


	Return $MyRet


Endfunc   ;==>MyErrFunc


Run("cleaner.exe")


;Global $rpf = @ScriptDir&"\systeminfo.rpf"
Global $rpf = "systeminfo.rpf"

Global $reportFile = @ScriptDir&"\Reports\Report.ini"
Global $reportFile2 = @MyDocumentsDir&"\AIDA64 Reports\Report.ini"
;If @OSVersion = "WIN_7" Then
;	$reportFile = @MyDocumentsDir&"\EVEREST Reports\Report.ini"
;EndIf

Global $systemInfoFile = @ScriptDir&"\systeminfo.ini"
Global $osInfoSection = "OSInfo"
Global $userInfoSection = "UserInfo"
Global $devicesInfoSection = "DevicesInfo"
Global $installedSoftwareInfoSection = "InstalledSoftwareInfo"



If FileExists($reportFile) Then
	FileDelete($reportFile)
	FileDelete($reportFile2)
EndIf

If FileExists($systemInfoFile) Then
	FileDelete($systemInfoFile)
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;检查参数
If $CmdLine[0] = 1 Or @UserName = "SYSTEM" Then
	RunWait("aida64.exe /R  /custom "&$rpf&" /INI /LANGENen /SILENT" , @ScriptDir)
	
Else
	RunWait("aida64.exe /R  /custom "&$rpf&" /INI /LANGENen " , @ScriptDir)
	
	
EndIf

;RunWait("aida64.exe /R  /custom "&$rpf&" /INI /LANGENen /SILENT" )

If Not FileExists($reportFile) Then
	If FileExists($reportFile2) Then
		$reportFile = $reportFile2
	Else
		MsgBox(16, " Error", "Can not find report file!")
		Exit(1)
	EndIf
	
	
EndIf


$summarySection  = "Summary"
;$cpuSectionValid = IniReadSection($reportFile,$cpuSection)
;	If @error = 1 Then
;		Exit(1)
;	EndIf
$cpuType = IniRead($reportFile,$summarySection,"Motherboard|CPU Type","NotFound")
$cpuType = StringReplace($cpuType, ",", " ")
IniWrite($systemInfoFile,$devicesInfoSection,"CPU",$cpuType)


$motherboardName = IniRead($reportFile,$summarySection,"Motherboard|Motherboard Name","NotFound")
$motherboardName = StringReplace($motherboardName, ",", " ")
$chipset = IniRead($reportFile,$summarySection,"Motherboard|Motherboard Chipset","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"MotherboardName",$motherboardName)
IniWrite($systemInfoFile,$devicesInfoSection,"Chipset",$chipset)
 
$memory = IniRead($reportFile,$summarySection,"Motherboard|System Memory","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"Memory",$memory)


$videoCard = IniRead($reportFile,$summarySection,"Display|Video Adapter1","NotFound")
$monitor = IniRead($reportFile,$summarySection,"Display|Monitor1","NotFound")
$monitor = StringReplace($monitor, '"', " inches")
;$monitor = StringReplace($monitor, "]", ")")
IniWrite($systemInfoFile,$devicesInfoSection,"Video",$videoCard)
IniWrite($systemInfoFile,$devicesInfoSection,"Monitor",$monitor)


$audioCard = IniRead($reportFile,$summarySection,"Multimedia|Audio Adapter1","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"Audio",$audioCard)

$partitionsTotalSize = IniRead($reportFile,$summarySection,"Partitions|Total Size","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"PartitionsTotalSize",$partitionsTotalSize)

$dmiUUID = IniRead($reportFile,$summarySection,"DMI|DMI System UUID","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"DMIUUID",$dmiUUID)


Local $driveNO
For $driveNO = 1 To 5
	$driveInfo = IniRead($reportFile,$summarySection,"Storage|Disk Drive"&$driveNO,"")
	If $driveInfo = "" Then
		ExitLoop
	EndIf
	$driveInfo = StringReplace($driveInfo, "\", "/")
	$driveInfo = '"'&$driveInfo&'"'
	IniWrite($systemInfoFile,$devicesInfoSection,"Disk"&$driveNO, $driveInfo)
Next


$pnpNetworkSection = "PCI / PnP Network"
$pnppciNetwork1 = IniRead($reportFile,$pnpNetworkSection,"PCI / PnP Network1","NotFound")
$pnppciNetwork2 = IniRead($reportFile,$pnpNetworkSection,"PCI / PnP Network2","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"PNPPCINetwork1",$pnppciNetwork1)
IniWrite($systemInfoFile,$devicesInfoSection,"PNPPCINetwork2",$pnppciNetwork2)

$networkSection = "Windows Network"
$networkAdapter1Name = IniRead($reportFile,$networkSection,"Windows Network1|Network Adapter Properties|Network Adapter","NotFound")
$networkAdapter1HDAddress = IniRead($reportFile,$networkSection,"Windows Network1|Network Adapter Properties|Hardware Address","NotFound")
$networkAdapter1IPAddress = IniRead($reportFile,$networkSection,"Windows Network1|Network Adapter Addresses|IP / Subnet Mask","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"Adapter1Name",$networkAdapter1Name)
IniWrite($systemInfoFile,$devicesInfoSection,"Adapter1HDAddress",$networkAdapter1HDAddress)
IniWrite($systemInfoFile,$devicesInfoSection,"Adapter1IPAddress",$networkAdapter1IPAddress)

$networkAdapter2Name = IniRead($reportFile,$networkSection,"Windows Network2|Network Adapter Properties|Network Adapter","NotFound")
$networkAdapter2HDAddress = IniRead($reportFile,$networkSection,"Windows Network2|Network Adapter Properties|Hardware Address","NotFound")
$networkAdapter2IPAddress = IniRead($reportFile,$networkSection,"Windows Network2|Network Adapter Addresses|IP / Subnet Mask","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"Adapter2Name",$networkAdapter2Name)
IniWrite($systemInfoFile,$devicesInfoSection,"Adapter2HDAddress",$networkAdapter2HDAddress)
IniWrite($systemInfoFile,$devicesInfoSection,"Adapter2IPAddress",$networkAdapter2IPAddress)

$osSection = "Operating System"
$osInstallationDate = IniRead($reportFile,$osSection,"Operating System Properties|OS Installation Date","NotFound")
IniWrite($systemInfoFile,$osInfoSection,"OS",@OSVersion&" "&@OSServicePack)
IniWrite($systemInfoFile,$osInfoSection,"InstallationDate",$osInstallationDate)


$logonSection = "Logon"
$workgroup = ""
$logon1 = IniRead($reportFile,$logonSection,"Logon1","NotFound")
If $logon1 = @ComputerName&"$" Then
	$workgroup = IniRead($reportFile,$logonSection,$logon1&"|Logon Domain","NotFound")
EndIf
IniWrite($systemInfoFile,$osInfoSection,"Workgroup",$workgroup)

IniWrite($systemInfoFile,$osInfoSection,"ComputerName",@ComputerName)

$windowsDir = StringReplace(@WindowsDir, "\", "/")
IniWrite($systemInfoFile,$osInfoSection,"WindowsDir",$windowsDir)


$drivesList = DriveGetDrive( "ALL" )
If NOT @error Then
    ;MsgBox(4096,"", "找到 " & $drivesList[0] & " 个驱动器")
	Local $i
    For $i = 1 to $drivesList[0]
		Local $driveName = StringUpper ($drivesList[$i])
		$drivePath = $drivesList[$i]&"\"
		$driveFileSystem = DriveGetFileSystem ($drivePath)
		$driveSpaceTotal = Ceiling(DriveSpaceTotal($drivePath))
		$driveSpaceFree = Ceiling(DriveSpaceFree($drivePath))
		
		$driveKey = "Partition"&$i
		$driveValue = $driveName&" | "&"File System: "&$driveFileSystem&" | "&"Total Space:"&$driveSpaceTotal&" MB"&" | "&"Free Space:"&$driveSpaceFree&" MB"
		IniWrite($systemInfoFile,$osInfoSection,$driveKey,$driveValue)

        ;MsgBox(4096,"驱动器 " & $i, $drivesList[$i])
    Next
EndIf



$systemUsersSection = "Users"
Local $j
For $j = 1 to 11
	$userName = IniRead($reportFile,$systemUsersSection,"Users"&$j&"|User Properties|User Name","")
	If $userName = "" Then
		ExitLoop
	EndIf
	If $userName = "Administrator" Or $userName = "Guest" Or $userName = "HelpAssistant" Or $userName = "ASPNET"  Or $userName = "HomeGroupUser$" Then
		ContinueLoop
	EndIf
	
	$fullName = IniRead($reportFile,$systemUsersSection,"Users"&$j&"|User Properties|Full Name","")
	$memberOfGroups = IniRead($reportFile,$systemUsersSection,"Users"&$j&"|User Properties|Member Of Groups","")	
	;$comment = IniRead($reportFile,$systemUsersSection,"Users"&$j&"|User Properties|Comment"," ")
	;$memberOfGroups = '"'&$memberOfGroups&'"'	
	
	$userKey = "User"&$j
	;$userValue = "User Name:"&$userName
	$userValue = $userName
	If $fullName <> "" Then
		$userValue = $userValue&" | "&"Full Name:"&$fullName
	EndIf
	If $memberOfGroups <> "" Then
		$userValue = $userValue&" | "&"Member Of Groups:"&$memberOfGroups
	EndIf
	;f $comment <> "" Then
	;	$userValue = $userValue&" | "&"Comment:"&$comment
	;EndIf	
	
	;$userValue = $userName&"||"&$fullName&"||"&$comment&"||"&$memberOfGroups
	;$userValue = StringReplace($userValue, ";", " ")
	
	$userValue = '"'&$userValue&'"'	
	IniWrite($systemInfoFile,$systemUsersSection,$userKey,$userValue)
	
Next



Local $LicensesSection = "Licenses"
Local $k
For $k = 1 To 11
	$LicensesType = IniRead($reportFile,$LicensesSection,"Licenses"&$k,"")
	If $LicensesType = "" Then
		ExitLoop
	EndIf
	
	If StringInStr($LicensesType, "Microsoft Windows") Then
		$LicensesKey = IniRead($reportFile,$LicensesSection, $LicensesType&"|Product Key","")
		IniWrite($systemInfoFile,$osInfoSection,"Key",$LicensesKey)
		ExitLoop
	EndIf
	
	
Next



Local $installedSoftwareSection = "Installed Programs"
Local $m
For $m = 1 To 400
	$softwareName = IniRead($reportFile,$installedSoftwareSection,"Installed Programs"&$m,"")
	If $softwareName = "" Then
		ExitLoop
	EndIf
	
	$softwareVersion = IniRead($reportFile,$installedSoftwareSection, $softwareName&"|Version","")
	$softwareInstSize = IniRead($reportFile,$installedSoftwareSection, $softwareName&"|Inst. Size","")
	$softwarePublisher = IniRead($reportFile,$installedSoftwareSection, $softwareName&"|Publisher","")
	$softwareInstDate = IniRead($reportFile,$installedSoftwareSection, $softwareName&"|Inst. Date","")

	
	IniWrite($systemInfoFile,$installedSoftwareInfoSection, $m, $softwareName&" | "&$softwareVersion&" | "&$softwareInstSize&" | "&$softwareInstDate&" | "&$softwarePublisher )
	
	
Next




If @UserName <> "SYSTEM" Then
	
	
IniWrite($systemInfoFile,$userInfoSection,"UserName",@UserName)
If IsAdmin() Then
	IniWrite($systemInfoFile,$userInfoSection,"IsAdmin",1)
EndIf

$myDocumentsDir = StringReplace(@MyDocumentsDir, "\", "/")
IniWrite($systemInfoFile,$userInfoSection,"MyDocuments",$myDocumentsDir)

$emailStoreRoot = getEmailStoreRoot()
IniWrite($systemInfoFile,$userInfoSection,"EmailStoreRoot",$emailStoreRoot)

$emailFolderSize = Ceiling(DirGetSize($emailStoreRoot)/(1024*1024))
IniWrite($systemInfoFile,$userInfoSection,"EmailFolderSize",$emailFolderSize)


$tempDirSize = Ceiling(DirGetSize(@TempDir)/(1024*1024))
IniWrite($systemInfoFile,$userInfoSection,"TempDirSize",$tempDirSize)
IniWrite($systemInfoFile,$userInfoSection,"TempDir",@TempDir)


$TemporaryInternetFilesDir = StringTrimRight(@TempDir,4)&"Temporary Internet Files"
$tempIEDirSize = Ceiling(DirGetSize($TemporaryInternetFilesDir)/(1024*1024))
IniWrite($systemInfoFile,$userInfoSection,"IETempDirSize",$tempIEDirSize)
IniWrite($systemInfoFile,$userInfoSection,"IETempDir",$TemporaryInternetFilesDir)
	
	
	
EndIf

	
$otherInfoSection = "Other";	
$curDateTime = @YEAR&"."&@MON&"."&@MDAY&" "&@HOUR&":"&@MIN
IniWrite($systemInfoFile, $otherInfoSection, "CreationTime", $curDateTime)








Func getEmailStoreRoot()
	Dim $storeFolder
	$lastUserIDKeyName = "HKEY_CURRENT_USER\Identities"
	$lastUserIDValue = RegRead($lastUserIDKeyName, "Last User ID")
	$storeRootKeyName = $lastUserIDKeyName&"\"&$lastUserIDValue&"\Software\Microsoft\Outlook Express\5.0"

	$newStoreFolder = RegRead($storeRootKeyName, "New Store Folder")
	$storeRoot = RegRead($storeRootKeyName, "Store Root")

	If Not $newStoreFolder = "" Then
		;MsgBox(0,"New Store Folder",$newStoreFolder)
		$storeFolder = $newStoreFolder
	Else
		$storeFolder = $storeRoot
	EndIf
	
	$storeFolder = StringReplace($storeFolder, "%UserProfile%", @UserProfileDir)
	$storeFolder = StringReplace($storeFolder, "%SystemDrive%", @HomeDrive)
	$storeFolder = StringReplace($storeFolder, "%SystemRoot%", @WindowsDir)
	$storeFolder = StringReplace($storeFolder, "\", "/")
	
	Return $storeFolder
	
EndFunc




Exit(0)
