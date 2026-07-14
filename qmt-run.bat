@echo off
title QMT-Executor
cd /d %~dp0

:: ====================================================
:: ����˵�����뽫�·�·����Ϊ����ʵ�� QMT ��װĿ¼��ִ����Ŀ¼
:: ע�⣺SINGLETON_PORT ������ Python ִ��������� main.py �е� _SINGLETON_PORT (Ĭ�� 59999) ����һ�£�
:: ====================================================
set "QMT_ROOT=C:\path\to\your\qmt_install_dir"
set "EXECUTOR_DIR=%~dp0"
set "SINGLETON_PORT=59999"
:: ====================================================

set "USERDATA_MINI=%QMT_ROOT%\userdata_mini"
set "QMT_EXE=%QMT_ROOT%\bin.x64\XtItClient.exe"

:: �����ظ�������ԭ����һ���Լ�⣩
echo [���] ���ڼ��ϵͳ����״̬...

set "EXECUTOR_RUNNING=0"
set "QMT_RUNNING=0"

:: A. ͨ�����԰󶨶˿������ Python ִ�����Ƿ���������
uv run python -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.bind(('127.0.0.1', %SINGLETON_PORT%))" >nul 2>&1 || set "EXECUTOR_RUNNING=1"

:: B. ����·���µ� QMT �ͻ��˽��� (XtMiniQmt.exe) �Ƿ���������
wmic process where "name='XtMiniQmt.exe'" get ExecutablePath 2>nul | find /i "%QMT_ROOT%" >nul && set "QMT_RUNNING=1"

:: �������һ��������������뾯���߼�
if "%EXECUTOR_RUNNING%"=="1" goto SHOW_WARNING
if "%QMT_RUNNING%"=="1" goto SHOW_WARNING
goto START_CLEANUP

:SHOW_WARNING
echo ====================================================
if "%EXECUTOR_RUNNING%"=="1" echo [����] ��⵽ Python ִ�������������У��˿� %SINGLETON_PORT% ��ռ�ã���
if "%QMT_RUNNING%"=="1" echo [����] ��⵽��·���µ� QMT �ͻ��� (XtMiniQmt.exe) �Ѿ��������У�
echo [����] ���ȹر������еĳ��򡣱����ڽ��� 5 ����Զ��ر�...
echo ====================================================
ping -n 6 127.0.0.1 >nul
exit /b 0

:START_CLEANUP
:: ������������������־������ļ�
echo ====================================================
echo [����] ��ʼ��������Ŀ¼�е������ļ���
echo ====================================================

if exist "%USERDATA_MINI%\log" (
    echo [����] ���������־Ŀ¼��%USERDATA_MINI%\log
    rmdir /s /q "%USERDATA_MINI%\log" >nul 2>&1
    mkdir "%USERDATA_MINI%\log" >nul 2>&1
)
if exist "%USERDATA_MINI%\dumps" (
    echo [����] �����������ת��Ŀ¼��%USERDATA_MINI%\dumps
    rmdir /s /q "%USERDATA_MINI%\dumps" >nul 2>&1
    mkdir "%USERDATA_MINI%\dumps" >nul 2>&1
)

echo [����] ����ɨ�貢��� *__mutex ���ļ�...
if exist "%USERDATA_MINI%" (
    dir /b /s "%USERDATA_MINI%\*__mutex" 2>nul
    del /f /q /s "%USERDATA_MINI%\*__mutex" >nul 2>&1
)
:: ���� miniQMT �ͻ���
echo [����] �������� miniQMT �ͻ���...
if exist "%QMT_EXE%" (
    start "" "%QMT_EXE%"
) else (
    echo [����] δ�ҵ� QMT ���ĳ������� QMT_ROOT ·������: %QMT_EXE%
    pause
    exit /b 1
)

:: ������֤������������ȴ� 60s��
echo [���] ���ڵȴ� miniQMT ��¼���������������� 60s��...
set "WAIT_COUNT=0"

:CHECK_LOOP
wmic process where "name='XtMiniQmt.exe'" get ExecutablePath 2>nul | find /i "%QMT_ROOT%" >nul
if not errorlevel 1 (
    echo [�ɹ�] ��⵽ XtMiniQmt.exe �����У�
    goto :START_PYTHON
)

set /a "WAIT_COUNT+=1"
if %WAIT_COUNT% geq 30 (
    echo ====================================================
    echo [����] ������ʱ��60s��������ʧ�ܣ����ֶ���飡����
    echo ====================================================
    pause
    exit /b 1
)

ping -n 3 127.0.0.1 >nul
goto :CHECK_LOOP

:START_PYTHON
:: ���� Python ִ����
echo [����] ����������ǰĿ¼�µ� Python ִ����...
cd /d %EXECUTOR_DIR%
uv run python main.py

