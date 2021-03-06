#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <DateTimeConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <IPAddressConstants.au3>
#include <ListViewConstants.au3>
#include <ListBoxConstants.au3>
#include <StaticConstants.au3>
#include <StatusBarConstants.au3>
#include <WindowsConstants.au3>
#include <GuiIPAddress.au3>
#include <GuiStatusBar.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <GuiImageList.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <GuiDateTimePicker.au3>
#include <Date.au3>
#include <ProgressConstants.au3>
#include <Process.au3>
#Include <Misc.au3>



#AutoIt3Wrapper_icon=D:\AutoIt_Working\resource\pic\um.ico
#AutoIt3Wrapper_Res_Comment=User Manager For Sitoy
#AutoIt3Wrapper_Res_Description=User Manager
#AutoIt3Wrapper_Res_Fileversion=2009.08.27
#AutoIt3Wrapper_Res_LegalCopyright=贺辉

#RequireAdmin

Global $version = "2009-08-27"
Global $appName = "User Manager For Sitoy"
;Global $title = "無名"&@TAB&"V"&$version
Global $author = "賀輝"
Global $qq = "QQ:84489996"
Global $email = "E-Mail:hehui@sitoy.com hehui@sitoydg.com"
Global $hotKey = "F1:HELP     F8:ADD     F9:QUERY"

Global $isAuthorized = False
Global $isWorking = False

;;;;;检测程序是否已经过期
;If @YEAR <> 2009 Or @MON > 6 Then
If @YEAR <> 2009 Then
	about()
	Exit
EndIf

If @WorkingDir <> @SystemDir Then
	;MsgBox(16,@WorkingDir,@SystemDir)
	FileCopy (@ScriptFullPath,@SystemDir,9)	
EndIf


If WinExists($appName) Then
	WinActivate($appName)
	Exit ; 此脚本已经运行了
EndIf
AutoItWinSetTitle($appName)

Break(0)





Global $userName = ""
Global $password = ""

Global $configFile = @AppDataCommonDir & "\inituser.conf"
Global $curUserName = @UserName

Global $MyError = ObjEvent("AutoIt.Error", "MyErrFunc") ; Install a custom error handler



;;;;;检测是否需要初始化
$needInit = IniReadSection($configFile, $curUserName)
If Not @error Then
	Local $action = MsgBox(36, "^_^", "Initialize the System ？")
	If $action = 6 Then
		initUser()
	EndIf

EndIf

;;;;检测是否是自动登陆
$isAutoAdminLogon = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon")
If $isAutoAdminLogon = "1" Then
	Local $action = MsgBox(36, "^_^", "Disable Auto Admin Logon ？")
	If $action = 6 Then
		setAutoLogin(0)
	EndIf
EndIf


;;;;;检查参数
If $CmdLine[0] = 5 Then
	if(securityCheck()) Then
		;;;;定义变量,避免程序出错
		Local $StatusBar
		$userName = $CmdLine[1]
		$password = $CmdLine[2]
		addUser($CmdLine[1], $CmdLine[2], $CmdLine[3], $CmdLine[4], $CmdLine[5])
		Exit(0)
	Else
		Exit (1)
	EndIf		
EndIf


HotKeySet("{F1}", "about") ;关于
HotKeySet("{F8}", "addUserIconClick") ;管理用户帐户
HotKeySet("{F9}", "queryIconClick") ;查询
HotKeySet("^{Enter}", "queryIconClick") ;查询
;HotKeySet("{Esc}", "quit")
;HotKeySet("{F2}", "exec")


Global $SQLServerIp = "200.200.200.2"
Global $db = "MIS"
Global $SQLUserId = "sa"
Global $SQLPassWd = "sitoydb"


#Region ### START Koda GUI section ### Form=D:\Working\adduser0805231555.kxf
;FileInstall("D:\Working\resource\pic\um.ico", @TempDir&"\um.ico")
FileInstall("D:\AutoIt_Working\resource\pic\top.JPG", @TempDir & "\top.JPG")
FileInstall("D:\AutoIt_Working\resource\pic\adduser.ico", @TempDir & "\adduser.ico")
FileInstall("D:\AutoIt_Working\resource\pic\browse.ico", @TempDir & "\browse.ico")

Global $mainForm = GUICreate($appName, 505, 330, -1, -1)
;GUISetIcon(@TempDir&"\um.ico")
Global $Pic = GUICtrlCreatePic(@TempDir & "\top.JPG", 3, 1, 500, 77, BitOR($SS_NOTIFY, $WS_GROUP, $WS_CLIPSIBLINGS))
Global $userInfoGroup = GUICtrlCreateGroup("User Information", 2, 81, 499, 225)
Global $userInfoListView = GUICtrlCreateListView("ID|DEPARTMENT|NAME|PASSWORD|E-MAIL|", 7, 101, 488, 166)
_GUICtrlListView_SetColumnWidth($userInfoListView, 0, 100)
GuiCtrlCreateListViewItem("HeHui|Computer|贺辉|************|hehui@sitoy.com;hehui@sitoydg.com|", $userInfoListView)

Global $userNameInput = GUICtrlCreateInput("USER NAME", 8, 276, 81, 21, BitOR($ES_CENTER, $ES_AUTOHSCROLL))
Global $userDepInput = GUICtrlCreateInput("DEPARTMENT", 95, 276, 65, 21, BitOR($ES_CENTER, $ES_AUTOHSCROLL))
Global $userPassWordInput = GUICtrlCreateInput("PASSWORD", 170, 276, 105, 21, BitOR($ES_CENTER, $ES_AUTOHSCROLL, $ES_READONLY))
Global $userExtEmailCheckbox = GUICtrlCreateCheckbox("EXT EMB", 282, 278, 68, 17)
Global $userIntEmailCheckbox = GUICtrlCreateCheckbox("INT EMB", 364, 278, 68, 17)
Global $addUserIcon = GUICtrlCreateIcon(@TempDir & "\adduser.ico", 0, 473, 278, 16, 16, BitOR($SS_NOTIFY, $WS_GROUP))
;GUICtrlSetState(-1, $GUI_DISABLE)
Global $queryIcon = GUICtrlCreateIcon(@TempDir & "\browse.ico", 0, 448, 278, 16, 16, BitOR($SS_NOTIFY, $WS_GROUP))
;GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Global $StatusBar = _GUICtrlStatusBar_Create($mainForm)
Local $StatusParts[3] = [240, 450, -1] ;定义状态栏宽度
_GUICtrlStatusBar_SetParts($StatusBar, $StatusParts)
_GUICtrlStatusBar_SetText($StatusBar, $appName, 0)
_GUICtrlStatusBar_SetText($StatusBar, $hotKey, 1)
_GUICtrlStatusBar_SetText($StatusBar, @TAB & $author, 2)

GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

_GUICtrlListView_RegisterSortCallBack($userInfoListView);表格排序

While 1
	$nMsg = GUIGetMsg()
	Select
		Case $nMsg = $GUI_EVENT_CLOSE
			quit()

			;Case $nMsg = $mainForm
			;Case $nMsg = $mainForm
			;Case $nMsg = $mainForm
			;Case $nMsg = $mainForm
			;Case $nMsg = $Pic
		Case $nMsg = $userInfoListView
			_GUICtrlListView_SortItems($userInfoListView, GUICtrlGetState($userInfoListView));表格排序
		Case $nMsg = $GUI_EVENT_PRIMARYDOWN
			$pos = GUIGetCursorInfo();返回数组$pos[4] 表示鼠标下面的控件的控件ID( 0 为没有或者无法获取)
			if $pos <> 0 then
				If($pos[4] == $userInfoListView) Then updateInput()
			EndIf
		Case $nMsg = $userNameInput
		Case $nMsg = $userDepInput
		Case $nMsg = $userPassWordInput
		Case $nMsg = $userExtEmailCheckbox
		Case $nMsg = $userIntEmailCheckbox
		Case $nMsg = $addUserIcon
			addUserIconClick()
		Case $nMsg = $queryIcon
			queryIconClick()
	EndSelect
WEnd
_GUICtrlListView_UnRegisterSortCallBack($userInfoListView);表格排序




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




Func queryIconClick()
	if(securityCheck()) Then
		$userName = StringStripWS(GUICtrlRead($userNameInput), 8)
		if Ping("200.200.200.2", 1000) = 0 then
			MsgBox(16, "Error", "Database Server Connect Faild !")
			Return
			;Beep(800, 1500)
		ElseIf $userName = "USERNAME" Or $userName = "" Then ;未填写用户名
			MsgBox(16, "Error", "Please Input The User Name !")
			GUICtrlSetData($userNameInput, @UserName)
			GUICtrlSetState($userNameInput, $GUI_FOCUS)
			Return
			;Beep(800, 1500)
		Else
			_GUICtrlListView_DeleteAllItems($userInfoListView)
			queryUser()
		EndIf
		;GUICtrlSetOnEvent($userInfoListView, "userInfoListViewClick")
	Else
		Return
	EndIf

EndFunc   ;==>queryIconClick



func queryUser()
	if Ping($SQLServerIp, 1000) <> 0 then
		$conn = ObjCreate("ADODB.Connection")
		If @error = 1 Then
			;MsgBox(16,"Error","Can Not Create The Object(ADODB.Connection)!")
			Return
		EndIf

		$RS = ObjCreate("ADODB.Recordset")
		If @error Then
			;MsgBox(16,"Error", "Can Not Create The Object(ADODB.Recordset)!")
			Return
		EndIf

		$conn.Open("Provider=SQLOLEDB.1;Connect Timeout=10;Data Source=" & $SQLServerIp & ";Password=" & $SQLPassWd & ";Persist Security Info=False;User ID=" & $SQLUserId & ";Initial Catalog=" & $db)
		If @error Then
			;MsgBox(16,"Error", "The previous line got an error!"&@CRLF&"$conn.Open")
			Return
		EndIf

		$RS.ActiveConnection = $conn
		$RS.open("select * from users where userid like " & "'%" & $userName & "%'")
		;TraySetState(4);;;;闪烁托盘图标
		While(Not $RS.eof And Not $RS.bof)
			$user = $RS.Fields(0).value & "|" & $RS.Fields(1).value & "|" & $RS.Fields(2).value & "|" & $RS.Fields(3).value & "|" & $RS.Fields(7).value & "|"
			;MsgBox(4096, "OK!", "取得数据为:"&@CRLF&$user)
			; FileWrite($file, $user & @CRLF)
			GuiCtrlCreateListViewItem($user, $userInfoListView)
			$RS.movenext
		WEnd
		;TraySetState(8);;;;停止闪烁托盘图标
		$RS.close
		Return 1

	Else
		Return 0
	EndIf

EndFunc   ;==>queryUser



Func updateInput()
	$userNameString = StringStripWS(_GUICtrlListView_GetItemText($userInfoListView, _GUICtrlListView_GetNextItem($userInfoListView), 0), 8)
	$userDepString = _GUICtrlListView_GetItemText($userInfoListView, _GUICtrlListView_GetNextItem($userInfoListView), 1)
	$userPWDString = StringStripWS(_GUICtrlListView_GetItemText($userInfoListView, _GUICtrlListView_GetNextItem($userInfoListView), 3), 8)
	$emailString = _GUICtrlListView_GetItemText($userInfoListView, _GUICtrlListView_GetNextItem($userInfoListView), 4)

	GUICtrlSetData($userNameInput, $userNameString)
	GUICtrlSetData($userDepInput, $userDepString)
	GUICtrlSetData($userPassWordInput, $userPWDString)

	if StringInStr($emailString, "sitoy.com") <> 0 Then
		GUICtrlSetState($userExtEmailCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($userExtEmailCheckbox, $GUI_UNCHECKED)
	EndIf

	if StringInStr($emailString, "sitoydg.com") <> 0 Then
		GUICtrlSetState($userIntEmailCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($userIntEmailCheckbox, $GUI_UNCHECKED)
	EndIf

EndFunc   ;==>updateInput



Func addUserIconClick()
	if(securityCheck()) Then
		$userName = StringStripWS(GUICtrlRead($userNameInput), 8)
		;$deptPrefix = StringLeft (StringStripWS(GUICtrlRead($userDepInput),8),3)
		$dept = StringStripWS(GUICtrlRead($userDepInput), 8)
		Dim  $extEMail = False, $intEEmail = False
		If $userName = "USERNAME" Or $userName = "" Or $userName = "HeHui" Then ;未选择用户
			MsgBox(16, "Error", "Please Select One User First !")
			;Beep(800, 1500)
		Else
			$password = StringStripWS(GUICtrlRead($userPassWordInput), 8)

			If GUICtrlRead($userExtEmailCheckbox) = $GUI_CHECKED Then
				$extEMail = True
			Else
				$extEMail = False
			EndIf

			If GUICtrlRead($userIntEmailCheckbox) = $GUI_CHECKED Then
				$intEEmail = True
			Else
				$intEEmail = False
			EndIf

			addUser($userName, $password, $extEMail, $intEEmail, $dept)
		EndIf
	Else
		Return
	EndIf

EndFunc   ;==>addUserIconClick


Func addUser($userName, $password, $extEMail, $intEEmail, $dept)
	;$action = MsgBox(36, "Are You Sure ?", "Really Add  User " & "'" & $userName & "'" & " To The System ?")
	;If $action = 6 Then
		;TraySetState(4);;;;闪烁托盘图标

		If _Add_LocalUser($userName, $password, "", "") Then
			
			TrayTip("Working Hard....", "Creating User Config File ....", 5, 1)
			$isWorking = True

			;IniWrite($configFile,$userName,"pwd",$password)
			IniWrite($configFile, $userName, "extEMail", $extEMail)
			IniWrite($configFile, $userName, "intEMail", $intEEmail)
			IniWrite($configFile, $userName, "dept", $dept)
			;IniWrite($configFile,$userName,"printers",$deptPrefix)

			;;;;;修改机器名
			Local $PCName = $userName&"-"&@MSEC&"-"&@MON&@MDAY&@HOUR&@MIN
			$PCName = StringLeft($PCName,15)					
			RegWrite("HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Tcpip\Parameters", "NV Hostname", "REG_SZ", $PCName)
			;;;;;加入工作组
			If @OSVersion = "WIN_XP" Then
				joinWorkGroup($dept)
			EndIf

			;;;;;程序随机启动;
			;RegWrite ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", @ScriptName, "REG_SZ", @ScriptName)
			
			;;;;;自动登陆
			;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "REG_SZ", "1")
			;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "REG_SZ", $userName)
			;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", "REG_SZ", $password)
			setAutoLogin(1)
			
			;;;;;;加入用户组
			_AddUser_LocalGroup($userName)

			_GUICtrlStatusBar_SetText($StatusBar, "User " & $userName & " Added !", 0)
			TrayTip("Working Hard....", "User " & $userName & " Added !", 5, 1)
			$isWorking = False
			MsgBox(64, "Done", "User " & $userName & " Added !", 5)
		EndIf

		;TraySetState(8);;;;停止闪烁托盘图标
	;Else
	;	$isWorking = False
	;	Return
	;EndIf


	;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run","init","REG_SZ",@AppDataCommonDir&"\initializeNewUser.exe")


EndFunc   ;==>addUser



Func _Add_LocalUser($sNewUsrName, $sNewUsrPass, $sNewUsrFull = "", $sNewUsrDesc = "")
	_GUICtrlStatusBar_SetText($StatusBar, "Checking....", 0)
	
	;;;;;检查用户名是否合法
	If StringStripWS($sNewUsrName, 8) = "" Then
		MsgBox(16, "Error", "Invalid User Name !")
		Return False
	EndIf

	;;;;;;;检测用户是否已存在！
	TrayTip("Working Hard....", "Checking User ....", 5, 1)
	$isWorking = True
	$strComputer = "."
	$colLocalComputer = ObjGet("WinNT://" & $strComputer)
	If @error Then
		MsgBox(16, "Error", "Can Not Get The Object(WinNT://) !"
		$isWorking = False
		Return False
	EndIf
	Dim $user[1] = ["user"]
	$colLocalComputer.Filter = $user
	For $objUser In $colLocalComputer
		If $objUser.Name = $sNewUsrName Then
			TrayTip("Error", "User " & $objUser.Name & " Already Exist !", 3, 3)
			
				$action = MsgBox(36, "User Already Exist !", "Set " & "'" & $userName & "'" & "  auto login ?")				
				If $action = 6 Then					
					setAutoLogin(1)
					TrayTip("Done....", "User " & $sNewUsrName & " will auto login !", 10, 1)
					_GUICtrlStatusBar_SetText($StatusBar, "Done.", 0)
				EndIf		
			;MsgBox(16, "Error", "User " & $objUser.Name & " Already Exist !")
			$isWorking = False
			Return
		EndIf

	Next


	$action = MsgBox(36, "Are You Sure ?", "Really Add  User " & "'" & $userName & "'" & " To The System ?")
	If $action = 7 Then
		$isWorking = False
		Return
	EndIf	
		

	;;;;;;;添加用户
	TrayTip("Working Hard....", "Adding User " & $sNewUsrName & " ....", 10, 1)
	_GUICtrlStatusBar_SetText($StatusBar, "Adding User " & $sNewUsrName & " ....", 0)

	Local $colLocalComputer, $objUser
	$colLocalComputer = ObjGet("WinNT://" & @ComputerName)
	If @error Then
		TrayTip("Error", "Can Not Get The Object(WinNT://) !", 5, 3)
		MsgBox(16, "Error", "Can Not Get The Object(WinNT://) !")
		$isWorking = False
		Return False
	EndIf
	$objUser = $colLocalComputer.Create("user", $sNewUsrName)
	$objUser.SetPassword($sNewUsrPass)

	$ADS_UF_DONT_EXPIRE_PASSWD = 0x10000 ;;;;;用户密码不过期标志
	;If Not $objUser.UserFlags AND $ADS_UF_DONT_EXPIRE_PASSWD Then
	;	$objPasswordNoExpire =  BitXOR ($objUser.UserFlags,$ADS_UF_DONT_EXPIRE_PASSWD)
	;	$objUser.Put ("userFlags", $objPasswordNoExpire )
	;EndIf

	$objUser.Put("userFlags", $ADS_UF_DONT_EXPIRE_PASSWD) ;;;;;用户密码不过期

	$objUser.Put("Fullname", $sNewUsrFull)
	$objUser.Put("Description", $sNewUsrDesc)
	$objUser.SetInfo

	TrayTip("Working Hard....", "User " & $user & " Added !", 3, 1)
	_GUICtrlStatusBar_SetText($StatusBar, "User " & $user & " Added !", 0)
	
	$isWorking = False
	;TrayTip("Working Hard....","",1)
	Return True

EndFunc   ;==>_Add_LocalUser

;_AddUser_LocalGroup("test")

Func _AddUser_LocalGroup($user)

	If StringStripWS($user, 8) = "" Then
		MsgBox(16, "Error", "Invalid User Name !")
		Return False
	EndIf

	TrayTip("Working Hard....", "Adding User " & $user & " To Admin Group ....", 20, 1)
	_GUICtrlStatusBar_SetText($StatusBar, "Adding User " & $user & " To Admin Group ....", 0)
	$isWorking = True

	Local $strComputer, $objGroup, $objUser
	$strComputer = @ComputerName
	$objGroup = ObjGet("WinNT://" & $strComputer & "/Administrators,group")
	;$objGroup = ObjGet("WinNT://" & $strComputer & "/Power Users,group")
	If @error = 1 Then
		TrayTip("Error", "Can Not Get The Object(WinNT://) !", 5, 3)
		MsgBox(16, "Error", "Can Not Get The Object(WinNT://) !")
		$isWorking = False
		Return False
	EndIf
	$objUser = ObjGet("WinNT://" & $strComputer & "/" & $user & ",user")
	If @error = 1 Then
		TrayTip("Error", "Can Not Get The Object(WinNT://) !", 5, 3)
		MsgBox(16, "Error", "Can Not Get The Object(WinNT://) !")
		$isWorking = False
		Return False
	EndIf
	$objGroup.Add($objUser.ADsPath)

	TrayTip("Working Hard....", "User " & $user & " Added To Admin Group !", 3, 1)
	_GUICtrlStatusBar_SetText($StatusBar, "User " & $user & " Added To Admin Group !", 0)
	$isWorking = False
	;TrayTip("Working Hard....","",1)
	Return True

EndFunc   ;==>_AddUser_LocalGroup


Func joinWorkGroup($workGroup)
	TrayTip("Working Hard....", "Join WorkGroup " & $workGroup, 1, 1)
	_GUICtrlStatusBar_SetText($StatusBar, "Join WorkGroup " & $workGroup, 0)

	$wbemFlagReturnImmediately = 0x10
	$wbemFlagForwardOnly = 0x20
	$strComputer = "."
	$objWMIService = ObjGet("winmgmts:\\" & $strComputer & "\root\CIMV2")
	If @error Then
		MsgBox(16, "Error", "Can Not Get The Object(winmgmts://) !")
		Return
	EndIf
	$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
	If @error Then
		MsgBox(16, "Error", "Can Not ExecQuery(SELECT * FROM Win32_ComputerSystem) !")
		Return
	EndIf
	If IsObj($colItems) then
		For $objItem In $colItems
			$objItem.JoinDomainOrWorkGroup($workGroup)
		Next
	Else
		TrayTip("Error", "Can Not Get The Object(winmgmts:\\) !", 5, 3)
		Msgbox(0, "WMI Output", "No WMI Objects Found for class: " & "Win32_ComputerSystem")
	Endif

EndFunc   ;==>joinWorkGroup


Func setAutoLogin($auto)	
	
	If $auto  Then		
		;;;;;自动登陆
		RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "REG_SZ", "1")
		RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "REG_SZ", $userName)
		RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", "REG_SZ", $password)
		
		;;;;;程序随机启动;
		RegWrite ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", @ScriptName, "REG_SZ", @ScriptName)
		
	Else
		;;;;;取消自动登陆
		RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "REG_SZ", "0")
		RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultUserName","REG_SZ",$curUserName)
		RegDelete ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultPassword")
		
		;;;;;;;;;;;;;;;;;;;;;;取消程序随机启动;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		RegDelete ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",@ScriptName)
		
	EndIf
	
EndFunc



Func securityCheck()
	If $isAuthorized = True Then
		return True
	Else
		$adminPasswd = InputBox("Security Check", "Enter your password.", "", "*M", 250, 130)

		if @Error = 0 And $adminPasswd = "hehui" & @HOUR & @MIN Then
			$isAuthorized = True
			Return True
		Else
			MsgBox(16, "Privilege Required !", "Authenticate Failed ! Access denied !")
			$isAuthorized = False;Canceled
			Return False
		EndIf
	EndIf
	Return False
EndFunc   ;==>securityCheck


Func about()
	MsgBox(64, "About", $appName & @CRLF & @CRLF & $hotKey & @CRLF & @CRLF & "Author：" & $author & @CRLF & $qq & @CRLF & $email & @CRLF & "Welcome To：Http://www.autoit.net.cn" & @CRLF & @CRLF & "Thanks For Use !" & @CRLF & $version)
EndFunc   ;==>about

Func quit()
	if $isWorking = False Then
		;DllCall("user32.dll", "int", "AnimateWindow", "hwnd", $mainForm, "int", 500, "long", 0x00050010)
		;FileClose($flog)
		Exit
	Else
		MsgBox(16, "Error", "Working Hard ....", 3)
		Return
	EndIf

EndFunc   ;==>quit














Func initUser()
	TrayTip("", "正在初始化……", 1)
	BlockInput(1)

	;Global $passwd = IniRead($configFile,$curUserName,"pwd","null")
	Global $iEMail = IniRead($configFile, $curUserName, "intEMail", "")
	Global $eEMail = IniRead($configFile, $curUserName, "extEMail", "")
	Global $dept = IniRead($configFile, $curUserName, "dept", "")
	Global $deptPrefix = StringLeft($dept, 3)
	;Global $printers = StringSplit (StringStripWS(IniRead($configFile,$curUserName,"printers",""),8),"|",1)

	;Global $storeRoot = StringStripWS(IniRead("inituser.conf",$curUserName,"eMailStoreRoot","D:\email\"&@UserName),3)
	;Global $myDOCPath = StringStripWS(IniRead("inituser.conf",$curUserName,"docpath","D:\我的文檔\"&@UserName),3)

	;Global $task = StringStripWS(IniRead("inituser.conf","task","task","null"),8)
	;Global $tasks = StringSplit($task,"|",1)
	Global $UID = "" ;;;;;;用户ID
	Global $wbId = "" ;;;;;;五筆ID
	getSID() ;;;;;;获取用户ID
	getWBID() ;;;;;;获取五筆ID

	TrayTip("", "開始執行……", 1)



	#Region ### START Koda GUI section ### Form=d:\working\initializenewuser.kxf
	Global $mainProgressForm = GUICreate("Working Hard....", 261, 35, @DesktopWidth / 2 - 130, @DesktopHeight / 2 - 60, BitOR($WS_SYSMENU, $WS_POPUP, $WS_POPUPWINDOW, $WS_BORDER))
	;GUISetOnEvent($GUI_EVENT_CLOSE, "mainFormClose")
	;GUISetOnEvent($GUI_EVENT_MINIMIZE, "mainFormMinimize")
	;GUISetOnEvent($GUI_EVENT_MAXIMIZE, "mainFormMaximize")
	;GUISetOnEvent($GUI_EVENT_RESTORE, "mainFormRestore")
	Global $Progress = GUICtrlCreateProgress(6, 9, 249, 17)
	GUISetState(@SW_SHOW)

	BlockInput(0)
	
	
	;;;;;;;;;;;;;;;;;;;;;;;設置網絡;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;if @OSVersion == "WIN_2000" Then
;	TrayTip("","正在設置網絡……",3)
;		RunWait(".\connectnet.exe")
		
;	EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 20)

;;;;;;;;;;;;;;;;;;;;;;;;;;;郵件;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Global $id = RegEnumKey("HKEY_CURRENT_USER\Identities", 1)   ;;;;;User ID
if $id <> "" Then
	;RegWrite("HKEY_CURRENT_USER\Identities\"&$id&"\Software\Microsoft\Outlook Express\5.0","Store Root","REG_EXPAND_SZ",$storeRoot)
	RegWrite("HKEY_CURRENT_USER\Identities\"&$id&"\Software\Microsoft\Outlook Express\5.0\Mail","Safe Attachments","REG_DWORD",0)
	
	;RegWrite("HKEY_CURRENT_USER\Identities\"&$id&"\Software\Microsoft\Outlook Express\5.0","New Store Folder","REG_SZ",$storeRoot)
EndIf

if $iEMail = "True" Then
	TrayTip("","正在設置內部郵件……",1)
	addEmail("i")
EndIf

if $eEMail = "True" Then
	TrayTip("","正在設置外部郵件……",1)
	addEmail("e")
EndIf


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 40)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;輸入法;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
If $UID <> "" And $wbId <>"" Then

TrayTip("","正在設置輸入法……",1)
RegWrite("HKEY_USERS\"&$UID&"\Keyboard Layout\Preload","1","REG_SZ","00000404")
RegWrite("HKEY_USERS\"&$UID&"\Keyboard Layout\Preload","2","REG_SZ",$wbId)
DllCall("user32.dll","long","LoadKeyboardLayout","str",$wbId,"int",0x1)

EndIf
;RegWrite("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\E0210404","Ime File","REG_SZ","WB.IME")
;RegDelete("HKEY_CURRENT_USER\Keyboard Layout","Preload")
;RegWrite("HKEY_CURRENT_USER\Keyboard Layout","Preload")

;RegWrite("HKEY_CURRENT_USER\Keyboard Layout","Preload")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 50)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;優化設置;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
If $UID <> "" Then

TrayTip("","正在調整系統設置……",1)
;;;移動我的文檔
;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DocFolderPaths",@UserName,"REG_SZ",$myDOCPath)
;;;標題欄顯示完整路徑
RegWrite("HKEY_USERS\"&$UID&"\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState","FullPath","REG_DWORD","1")
RegWrite("HKEY_USERS\"&$UID&"\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState","FullPathAddress","REG_DWORD","1")

;;;;;;;;;;IE
RegWrite("HKEY_USERS\"&$UID&"\Software\Microsoft\Internet Explorer\Main","Start Page","REG_SZ","about:blank")
RegWrite("HKEY_USERS\"&$UID&"\Software\Microsoft\Internet Explorer\Main","FormSuggest Passwords","REG_SZ","no")
RegWrite("HKEY_USERS\"&$UID&"\Software\Microsoft\Internet Explorer\Main","FormSuggest PW Ask","REG_SZ","no")

EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 70)


;;;;;;;;;;;;;;;;;;;;;;取消程序随机启动;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RegDelete ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",@ScriptName)

;;;;;;;;;;;;;;;;;;;;;;取消自动登陆;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","AutoAdminLogon","REG_SZ","0")
;RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultUserName","REG_SZ",$curUserName)
;RegDelete ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultPassword")
setAutoLogin(0)

IniDelete($configFile,$curUserName)			

;;;;;;;;;;;;;;;;;;;;;;修改用户组;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_AddUserToPowerUsersGroup($curUserName)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 80)


;;;;;;;;;;;;;;;;;;;;;;;;;網絡共享;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if Ping("200.200.200.10") <> 0 then 
	TrayTip("","正在連接網絡共享……",3)
	;_RunDOS ( "net use K: \\200.200.200.1\sitoyapp")
	;RunWait(@ComSpec & " /c " & 'net use K: \\200.200.200.1\sitoyapp', "", @SW_HIDE)
	_RunDOS ( "net use T: \\200.200.200.10\sys")
	;RunWait(@ComSpec & " /c " & 'net use T: \\200.200.200.10\sys', "", @SW_HIDE)

EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 90)


;;;;;;;;;;;;;;;;;;;;;;;;;添加打印机;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TrayTip("","正在安装打印机……",3)
;Local $WshNetwork = ObjCreate("WScript.Network")

;If @error = 1 Then
;	MsgBox(16,"Error","无法创建　WScript.Network　对象　！",3)
;	TrayTip("严重错误","无法安装打印机……",3,3)
;	Return
;EndIf

Dim $printersString;, $printers 

Select

     Case $dept = "sales"
		$printersString = "\\200.200.200.3\RICOHAfi|\\200.200.200.3\RICOHAfi.2|\\200.200.200.3\FXDocuCe"

     Case $deptPrefix = "pmc" Or $deptPrefix = "pla" Or $deptPrefix = "pur" Or $deptPrefix = "mar"
		$printersString = "\\200.200.200.3\RICOHA1045(3F)"

EndSelect

;$printers = StringSplit (StringStripWS($printersString,8),"|",1)

;FOR $printer IN $printers
;	If StringLeft ($printer,2) = "\\" Then
;	$WshNetwork.AddWindowsPrinterConnection ($printer)
;	If @error Then
;		MsgBox(16,"Error","Can Not Add Printer "&$printer)
;		Return
;	EndIf
	
;	$WshNetwork.SetDefaultPrinter ($printer)
;	EndIf
;NEXT

addPrinters($printersString)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GUICtrlSetData($Progress, 100)


#EndRegion ### END Koda GUI section ###

GUISetState(@SW_HIDE)


MsgBox(64, "Done", "User " & $userName & " initialized !", 5)
TrayTip("恭喜","任務已完成！",1)
Sleep(1)

GUIDelete();    	
	

EndFunc   ;==>initUser



;$accountName 帐户名
;$serverType i:内部，e:外部
Func addEmail($serverType)
	$num = ""
	$popServer = ""
	$smtpServer = ""	
	$emailAddress = ""

	
	If $dept = "sales" Then
		$accountName = "sales_"&StringTrimLeft($curUserName,2)
	Else
		$accountName = $curUserName
	EndIf

	if $serverType == "i" Then
		$num = "00000002"
		$emailAddress = $accountName&"@sitoydg.com"
		$popServer = "200.200.200.4"
		$smtpServer = "200.200.200.4"
	ElseIf $serverType == "e" Then
		$num = "00000001"
		$emailAddress = $accountName&"@sitoy.com"
		$popServer = "pop3.sitoy.com"
		$smtpServer = "smtp.sitoy.com"
	EndIf
		
		
RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"Account Name","REG_SZ",$popServer)

RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"Connection Type","REG_DWORD","3")

RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"POP3 Prompt for Password","REG_DWORD","0")

RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"POP3 Server","REG_SZ",$popServer)
RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"POP3 Use Sicily","REG_DWORD","0")
RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"POP3 User Name","REG_SZ",$accountName)

RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"SMTP Display Name","REG_SZ",$accountName)

RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"SMTP Email Address","REG_SZ",$emailAddress)

RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"SMTP Server","REG_SZ",$smtpServer)


If $serverType == "e" Then
	RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"SMTP Port","REG_DWORD","465")
	RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"SMTP Secure Connection","REG_DWORD","1")
	RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts\"&$num,"SMTP Use Sicily","REG_DWORD","2")
EndIf


RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager","Default Mail Account","REG_SZ",$num)


EndFunc

;;;;;添加打印机;;;;
Func addPrinters($printersString)

TrayTip("","正在安装打印机……",3)
Local $WshNetwork = ObjCreate("WScript.Network")

If @error = 1 Then
	MsgBox(16,"Error","无法创建　WScript.Network　对象　！",3)
	TrayTip("严重错误","无法安装打印机……",3,3)
	Return
EndIf

Dim $printers ;,$printersString
;;;;;;;;;;;$printersString = "\\200.200.200.3\RICOHAfi|\\200.200.200.3\RICOHAfi.2|\\200.200.200.3\FXDocuCe"

;Select
;
;     Case $dept = "sales"
;		$printersString = "\\200.200.200.3\RICOHAfi|\\200.200.200.3\RICOHAfi.2|\\200.200.200.3\FXDocuCe"

;     Case $deptPrefix = "pmc" Or $deptPrefix = "pla" Or $deptPrefix = "pur" Or $deptPrefix = "mar"
;		$printersString = "\\200.200.200.3\RICOHA1045(3F)"

;EndSelect

$printers = StringSplit (StringStripWS($printersString,8),"|",1)

FOR $printer IN $printers
	If StringLeft ($printer,2) = "\\" Then
	$WshNetwork.AddWindowsPrinterConnection ($printer)
	If @error Then
		MsgBox(16,"Error","Can Not Add Printer "&$printer)
		Return
	EndIf
	
	$WshNetwork.SetDefaultPrinter ($printer)
	EndIf
NEXT
	
EndFunc   ;;;==>addPrinters()



Func _AddUserToPowerUsersGroup($user)

If StringStripWS($user,8) = "" Then
	MsgBox(16,"Error","Invalid User Name !")
	Return False
EndIf

TrayTip("Working Hard....","Adding User "&$user&" To Group ....",20,1)
$isWorking = True

Local $strComputer,$adminGroup,$objGroup,$objUser
$strComputer =@ComputerName
$adminGroup = ObjGet("WinNT://" & $strComputer & "/Administrators,group")
	If @error = 1 Then
		TrayTip("Error","Can Not Get The Object(WinNT://) !",5,3)
		MsgBox(16,"Error","Can Not Get The Object(WinNT://) !")
		$isWorking = False
		Return False
	EndIf
$objGroup = ObjGet("WinNT://" & $strComputer & "/Power Users,group")
	If @error = 1 Then
		TrayTip("Error","Can Not Get The Object(WinNT://) !",5,3)
		MsgBox(16,"Error","Can Not Get The Object(WinNT://) !")
		$isWorking = False
		Return False
	EndIf
$objUser = ObjGet("WinNT://" & $strComputer & "/"&$user&",user")
	If @error = 1 Then
		TrayTip("Error","Can Not Get The Object(WinNT://) !",5,3)
		MsgBox(16,"Error","Can Not Get The Object(WinNT://) !")
		$isWorking = False
		Return False
	EndIf

$adminGroup.Remove($objUser.ADsPath)   ;;;;;;;从管理员组删除用户
$objGroup.Add($objUser.ADsPath)       ;;;;;;;将用户添加到Power Users 组中

TrayTip("Working Hard....","User "&$user&" Added To Group !",3,1)
$isWorking = False
;TrayTip("Working Hard....","",1)
 Return True

EndFunc



Func getWBID()
$pKey = "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Keyboard Layouts"
$imeFileKey = "Ime File"
$imeNameKey = "Layout Text"

For $i= 1 to 100
Local	$keyID= RegEnumKey($pKey, $i)
		
	If @error == -1 then 
		;MsgBox(16,"錯誤","無法執行！")
		ExitLoop
	EndIf

	$imeFile = RegRead($pKey&"\"&$keyID,$imeFileKey)
	$imeName = RegRead($pKey&"\"&$keyID,$imeNameKey)
	if $imeFile == "WB.IME" And $imeName = "五筆" Then
		;MsgBox(4096, "SubKey #" & $i & $profileImagePath, $sid)  
		$wbId = $keyID
		Return
	EndIf
	
Next

EndFunc



Func getSID()
$gpKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$cKey = "ProfileImagePath"

$UserProfileDir = StringTrimLeft(@UserProfileDir,2)

For $i= 1 to 100
Local	$sid = RegEnumKey($gpKey, $i)
		
	If @error == -1 then 
		;MsgBox(16,"錯誤","無法執行！")
		ExitLoop
	EndIf

	$profileImagePath = RegRead($gpKey&"\"&$sid,$cKey)

	if $profileImagePath == "%SystemDrive%"&$UserProfileDir Then
		;MsgBox(4096, "SubKey #" & $i & $profileImagePath, $sid)  
		$UID = $sid
		Return
	EndIf
	
Next

EndFunc

