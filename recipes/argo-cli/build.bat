@echo on
setlocal enabledelayedexpansion

set YARN_ENABLE_IMMUTABLE_INSTALLS=false
call yarn --cwd ui install
if errorlevel 1 exit /b 1

call yarn --cwd ui build
if errorlevel 1 exit /b 1

go build ^
    -v ^
    -gcflags "" ^
    -ldflags "-X 'github.com/argoproj/argo-workflows/v3.version=v%PKG_VERSION%'" ^
    -o "%PREFIX%\bin\argo.exe" ^
    ./cmd/argo/
if errorlevel 1 exit /b 1

go-licenses save ./cmd/argo --ignore github.com/jmespath/go-jmespath --save_path ./library_licenses/
if errorlevel 1 exit /b 1
