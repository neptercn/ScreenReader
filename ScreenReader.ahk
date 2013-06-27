#SingleInstance,force
#InstallKeybdHook
#NoTrayIcon
intro:="
(
本软件由 nepter 编写，<a href=""http://ahk.appinn.com"">Autohotkey中文论坛</a> 管理组出品，感谢大家对Autohotkey的支持与热爱。

软件功能：按下热键（默认Capslock）获取鼠标下的文字并储存到剪贴板中，能够获取包括窗口、网页、QQ聊天窗口里的各种文字，不能识别图片。要切换大小写，请按shift+capslock

运行环境：Win XP sp3以上

版本号  ：0.1.1

编译环境：Autohotkey_L 1.1.10

未来计划：增强识别率，更多功能  <a href=""http://ahk.appinn.com"">敬请期待</a>

)"
menu,tray,NoStandard
menu,tray,add,热键,hotkey
menu,tray,add,关于...,about
menu,tray,add,退出,exit
CoordMode,mouse,screen
KeyName:="capslock"
Hotkey,%KeyName%,main
if !uia:=ComObjCreate("{ff48dba4-60ef-4201-aa87-54103eef594e}","{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}"){
  msgbox 初始化失败了，自动退出。
	ExitApp
}
return
+CapsLock::CapsLock
exit:
	exitapp
hotkey:
	gui,1:Destroy
	gui,1:add,text,,输入新热键
	gui,1:add,Hotkey,vChosenHotkey,%KeyName%
	gui,1:add,button,Default gbtnHK,确定
	gui,1:show,,%A_Space%
	return
about:
	gui,2:Destroy
	gui,2:add,link,,%intro%
	gui,2:show,,关于 ScreenReader 0.1.1
	return
btnHK:
	gui,1:submit
	if (ChosenHotkey!=KeyName){
		Hotkey,%KeyName%,,off
		KeyName:=ChosenHotkey
		Hotkey,%KeyName%,main,on
	}
	gui,1:Destroy
	return
main:
	MouseGetPos,x,y
	item:=GetElementItem(x,y)
	if !item.1
		return
	gui,3:Destroy
	;gui,3:new,ToolWindow
	for k,v in item
	{
		gui,3:add,edit,x5 w480 -Tabstop vedit%k%,%v%
		GuiControlGet,pos,3:Pos,edit%k%
		if (posh>800)
			GuiControl,3:Move,edit%k%,h800
		gui,3:add,button,X+5 yp-2 vbtn%k% gcp2cb,复制到剪贴板
	}
		gui,3:show,,你获取了
	return
cp2cb:
	n:=SubStr(A_GuiControl,4)
	GuiControlGet,txt,,edit%n%
	if txt
		Clipboard:=txt
	gui,3:Destroy
	return
3GuiEscape:
	gui,3:Destroy
	return
vas(obj,ByRef txt){
	for k,v in obj
		if (v=txt)
			return 0
	return 1
}
GetPatternName(id){
	global uia
	DllCall(vt(uia,50),"ptr",uia,"uint",id,"ptr*",name)
	return StrGet(name)
}
GetPropertyName(id){
	global uia
	DllCall(vt(uia,49),"ptr",uia,"uint",id,"ptr*",name)
	return StrGet(name)
}
GetElementItem(x,y){
	global uia
	item:={}
	DllCall(vt(uia,7),"ptr",uia,"int64",x|y<<32,"ptr*",element) ;IUIAutomation::ElementFromPoint
	if !element
		return
	DllCall(vt(element,23),"ptr",element,"ptr*",name) ;IUIAutomationElement::CurrentName
	DllCall(vt(element,10),"ptr",element,"uint",30045,"ptr",variant(val)) ;IUIAutomationElement::GetCurrentPropertyValue::value
	DllCall(vt(element,10),"ptr",element,"uint",30092,"ptr",variant(lname)) ;IUIAutomationElement::GetCurrentPropertyValue::lname
	DllCall(vt(element,10),"ptr",element,"uint",30093,"ptr",variant(lval)) ;IUIAutomationElement::GetCurrentPropertyValue::lvalue
	a:=StrGet(name),b:=StrGet(NumGet(val,8,"ptr")),c:=StrGet(NumGet(lname,8,"ptr")),d:=StrGet(NumGet(lval,8,"ptr"))
	a?item.Insert(a):0
	b&&vas(item,b)?item.Insert(b):0
	c&&vas(item,c)?item.Insert(c):0
	d&&vas(item,d)?item.Insert(d):0
	DllCall(vt(element,21),"ptr",element,"uint*",type) ;IUIAutomationElement::CurrentControlType
	if (type=50004) ;text:50020
		e:=GetElementWhole(element),e&&vas(item,e)?item.Insert(e):0
	ObjRelease(element)
	return item
}
GetElementWhole(element){
	global uia
	static init:=1,trueCondition,walker,root
	if init
		init:=DllCall(vt(uia,21),"ptr",uia,"ptr*",trueCondition) ;IUIAutomation::CreateTrueCondition
		,init+=DllCall(vt(uia,14),"ptr",uia,"ptr*",walker) ;IUIAutomation::ControlViewWalker
		,init+=DllCall(vt(uia,5),"ptr",uia,"ptr*",root) ;IUIAutomation::GetRootElement
	DllCall(vt(uia,3),"ptr",uia,"ptr",element,"ptr",root,"int*",same) ;IUIAutomation::CompareElements
	;ObjRelease(root)
	if same {
		return
	}
	hr:=DllCall(vt(walker,3),"ptr",walker,"ptr",element,"ptr*",parent) ;IUIAutomationTreeWalker::GetParentElement
	if parent {
		e:=""
		DllCall(vt(parent,6),"ptr",parent,"uint",2,"ptr",trueCondition,"ptr*",array) ;IUIAutomationElement::FindAll
		DllCall(vt(array,3),"ptr",array,"int*",length) ;IUIAutomationElementArray::Length
		loop % length {
			DllCall(vt(array,4),"ptr",array,"int",A_Index-1,"ptr*",newElement) ;IUIAutomationElementArray::GetElement
			DllCall(vt(newElement,23),"ptr",newElement,"ptr*",name) ;IUIAutomationElement::CurrentName
			e.=StrGet(name)
			ObjRelease(newElement)
		}
		ObjRelease(array)
		ObjRelease(parent)
		return e
	}
}
variant(ByRef var,type=0,val=0){
	return (VarSetCapacity(var,8+2*A_PtrSize)+NumPut(type,var,0,"short")+NumPut(val,var,8,"ptr"))*0+&var
}
vt(p,n){
	return NumGet(NumGet(p+0,"ptr")+n*A_PtrSize,"ptr")
}
