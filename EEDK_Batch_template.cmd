::@echo off
:: Version 1.0.3
::     .AUTHORS
::        steen_pedersen@ - 2022
::
pushd "%~dp0"
SET SRCDIR=
for /f "delims=" %%a in ('cd') do @set SRCDIR=%%a
setlocal ENABLEEXTENSIONS
setlocal EnableDelayedExpansion
:: Set the ISO Date to yyyymmddhhmmss using wmic
:: this is not possible using %date% as the format can be different based on date settings
for /F "tokens=2 delims==." %%I in ('wmic os get localdatetime /VALUE') do set "l_MyDate=%%I"
set ISO_DATE_TIME=%l_MyDate:~0,14%
set l_EEDK_Debug_log=%temp%\EEDK_Debug.log
echo %ISO_DATE_TIME% >>!l_EEDK_Debug_log!

:: ################################################
:: Must use ProgramW6432 as the ProgramFiles will point to C:\Program Files (x86) 
:: when The Agent (32bit) is executing the script
:: echo !ProgramW6432! >>%temp%\EEDK_Debug.log 2>>&1
::
:: Using sysnative 
:: Sysnative is a virtual folder, a special alias, that can be used to access the 64-bit 
:: System32 folder from a 32-bit application or script. If you for example specify this 
:: folder path in your application's source code:
:: C:\Windows\Sysnative
:: the following folder path is actually used:
:: C:\Windows\System32
:: Using the 'Sysnative' folder will help you access 64-bit tools from 32-bit code
:: Like: %windir%\sysnative\Manage-BDE.exe -status
:: The Manage-BDE.exe only exist in \System32\ folder and not in the SysWOW64
:: https://www.samlogic.net/articles/sysnative-folder-64-bit-windows.htm
:: ################################################

:: *******************
:: Execute the script and commands you need here
:: %SCRDIR% will point to the directory where the Agent is placing the files from the EEDK pacakge
:: Example:
:: %SCRDIR%\executable.exe /options A B C
:: *******************

:: Place the results to send back to ePO in Custom Props in l_results
:: Example 
set l_results=EEDK Script executed %ISO_DATE_TIME%


:: ---------------------------
:: Find path to McAfee Agent
::Read information from 64 bit
set KEY_NAME0=HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Network Associates\ePolicy Orchestrator\Agent
set VALUE_NAME0=Installed Path
FOR /F "skip=2 tokens=1,3*" %%A IN ('REG QUERY "%KEY_NAME0%" /v "%VALUE_NAME0%" 2^>nul') DO (set agent_path=%%C)
if [!agent_path!] == [] goto :Read_32_bit_information
::set Value1=%agent_path%\..\
::set agent_path=!Value1!
set agent_path=!agent_path!\..\
GOTO :Value_is_set
 
:Read_32_bit_information
set KEY_NAME0=HKEY_LOCAL_MACHINE\SOFTWARE\Network Associates\ePolicy Orchestrator\Agent
set VALUE_NAME0=Installed Path
FOR /F "skip=2 tokens=1,3*" %%A IN ('REG QUERY "%KEY_NAME0%" /v "%VALUE_NAME0%" 2^>nul') DO (set agent_path=%%C)
if [!agent_path!] == [] goto :no_value
:: --------------------------- 
  
:Value_is_set
:: Write results to Custom Props
::echo agent_path
::echo Agent Location: %agent_path%
::DEBUG TEST
::set l_results=Status method
%comspec% /c ""!agent_path!\maconfig.exe" -custom -prop8 "!l_results!""
%comspec% /c "%agent_path%\cmdagent.exe" -p
 
goto end_of_file
 
:no_value
echo No reg Value found
 
:end_of_file
:: Exit and pass proper exit to agent

popd
Exit /B 0
