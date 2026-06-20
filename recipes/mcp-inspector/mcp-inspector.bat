@echo off
:: %~dp0 expands to the script's directory with a trailing backslash,
:: so %~dp0.. resolves to PREFIX when this script is in PREFIX\Scripts\.
node "%~dp0..\lib\mcp-inspector\cli\build\cli.js" %*
