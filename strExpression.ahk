#Requires AutoHotkey v1.1.36+
#Include %A_ScriptDir%
#Include .\lib\StringEscapeUtils.ahk
;==============================================================
; StrExpression — Simple expression-like string resolver
;
; GitHub: https://github.com/SevenKeyboard/str-expression
; Author: SevenKeyboard Ltd. (2025)
; License: The Unlicense
;
; Documentation / References:
;   Expression Operators (in descending precedence order)
;     https://www.autohotkey.com/docs/v1/Variables.htm#operators
;==============================================================
class VersionManager_strExpression
{
    static _ := VersionManager_strExpression._init()
    _init()    {
        global
        STREXPRESSION_VERSION := "1.0.0"
        if (!this._verCheck(STRINGESCAPEUTILS_VERSION, "1.0.0"))
            throw exception("StringEscapeUtils version 1.x is required (minimum 1.0.0).")
        return true
    }
    _verCheck(byRef actual, required)    {
        if !isSet(actual)
            return false
        actualMajor     := strSplit(actual, ".",, 2)[1]
        requiredMajor   := strSplit(required, ".",, 2)[1]
        if (actualMajor !== requiredMajor)
            return false
        return verCompare(actual, ">=" required)
    }
}
strExpression(str)    {
    global ;  to enable dynamic variables to always reference global variables.
    local spo,out,m,temp:=[],tempvar
    spo:=1
    out:=""
    loop Parse, % str
    {
        if (A_Index!==spo)
            continue
        if (A_LoopField=="""")    { ;  String
            temp[1]:=subStr(str,spo)
            temp[1]:=strReplace(temp[1],"""""","__")
            if (!regExMatch(temp[1],"O)("".*?"")",m))    {
                errorLevel:=true
                return
            }
            temp[2]:=subStr(str,spo+1,m.len(0)-2)
            temp[2]:=strReplace(temp[2],"""""","""")
            out.=strEscape(temp[2])
            spo+=m.len(0)
            continue
        }  else if (A_LoopField~="[\w%]")    { ;  Variable
            temp[1]:=""
            if (1<=spo-1)    {
                temp[1]:=subStr(str,spo-1,1)
                if (temp[1]!==" " && temp[1]!=="`t")    {
                    errorLevel:=true
                    return
                }
            }
            temp[2]:=subStr(str,spo)
            if (!regExMatch(temp[2],"sDO`a)^([\w%]+)(?=[ `t]|$)",m))    {
                ;  Func()
                ;  Class.Method()
                ;  Class.Field
                ;  %func%()
                errorLevel:=true
                return
            }
            if (m[0]~="%")    {
                ;  Array%j%
                errorLevel:=true
                return
            }
            if (m[0]~="^\d+$" || m[0]~="^0[xX][a-fA-F0-9]+$")    {
                out.=m[0]
                spo+=m.len(0)
                continue
            }
            try tempvar:=m[0], out.=%tempvar%
            spo+=m.len(0)
            continue
        }
        ++spo
    }
    errorLevel:=false
    return out
}