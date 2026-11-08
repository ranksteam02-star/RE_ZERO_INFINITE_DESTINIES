@echo off
setlocal
cd /d "%~dp0.."
if not defined GODOT_BIN set "GODOT_BIN=godot"
"%GODOT_BIN%" --headless --path . --editor --import --quit
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --headless --path . res://tests/TestRunner.tscn
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --headless --path . res://tests/CampaignRunner.tscn
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --headless --path . res://tests/PersistenceRunner.tscn -- --write
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --headless --path . res://tests/PersistenceRunner.tscn -- --read
if errorlevel 1 exit /b 1
endlocal
