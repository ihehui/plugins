#include <ProgressConstants.au3>
#include <WindowsConstants.au3>
#include <Process.au3>



#AutoIt3Wrapper_icon=D:\Working\resource\pic\xp.ico
#AutoIt3Wrapper_Res_Comment=System information Collector For Sitoy
#AutoIt3Wrapper_Res_Description=System information Collector
#AutoIt3Wrapper_Res_Fileversion=2009.07.03
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


Global $rpf = @ScriptDir&"\systeminfo.rpf"
Global $reportFile = @ScriptDir&"\Reports\Report.ini"
Global $systemInfoFile = @ScriptDir&"\systeminfo.ini"
Global $osInfoSection = "OSInfo"
Global $userInfoSection = "UserInfo"
Global $devicesInfoSection = "DevicesInfo"


If FileExists($reportFile) Then
	FileDelete($reportFile)
EndIf

If FileExists($systemInfoFile) Then
	FileDelete($systemInfoFile)
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RunWait("everest.exe /R  /custom "&$rpf&" /INI /LANGENen /SILENT" )

If Not FileExists($reportFile) Then
	Exit(1)
EndIf

$cpuSection = "CPU"
;$cpuSectionValid = IniReadSection($reportFile,$cpuSection)
;	If @error = 1 Then
;		Exit(1)
;	EndIf
$cpuType = IniRead($reportFile,$cpuSection,"CPU Properties|CPU Type","NotFound")
$cpuType = StringReplace($cpuType, ",", " ")
IniWrite($systemInfoFile,$devicesInfoSection,"CPU",$cpuType)

$motherboardSection = "Motherboard"
$motherboardID = IniRead($reportFile,$motherboardSection,"Motherboard Properties|Motherboard ID","NotFound")
$motherboardName = IniRead($reportFile,$motherboardSection,"Motherboard Properties|Motherboard Name","NotFound")
$chipset = IniRead($reportFile,$motherboardSection,"Motherboard Physical Info|Motherboard Chipset","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"MotherboardID",$motherboardID)
IniWrite($systemInfoFile,$devicesInfoSection,"MotherboardName",$motherboardName)
IniWrite($systemInfoFile,$devicesInfoSection,"Chipset",$chipset)
 
$memorySection = "Memory"
$memory = IniRead($reportFile,$memorySection,"Physical Memory|Total","NotFound")
$memory = StringReplace($memory, "MB", "",1)
IniWrite($systemInfoFile,$devicesInfoSection,"Memory",$memory)


$videoSection = "PCI / AGP Video"
$videoCard = IniRead($reportFile,$videoSection,"PCI / AGP Video1","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"Video",$videoCard)


$audioSection = "PCI / PnP Audio"
$audioCard = IniRead($reportFile,$audioSection,"PCI / PnP Audio1","NotFound")
IniWrite($systemInfoFile,$devicesInfoSection,"Audio",$audioCard)


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
    For $i = 1 to $drivesList[0]
		$driveName = StringUpper ($drivesList[$i])
		$drivePath = $drivesList[$i]&"\"
		$driveFileSystem = DriveGetFileSystem ($drivePath)
		$driveSpaceTotal = Ceiling(DriveSpaceTotal($drivePath))
		$driveSpaceFree = Ceiling(DriveSpaceFree($drivePath))
		
		$driveKey = "Drive"&$i
		$driveValue = $driveName&" | "&"File System: "&$driveFileSystem&" | "&"Total Space:"&$driveSpaceTotal&" MB"&" | "&"Free Space:"&$driveSpaceFree&" MB"
		IniWrite($systemInfoFile,$osInfoSection,$driveKey,$driveValue)

        ;MsgBox(4096,"驱动器 " & $i, $drivesList[$i])
    Next
EndIf


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




;MsgBox(0,"",@LogonServer)
	
	