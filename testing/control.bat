@echo off
setlocal enabledelayedexpansion

:: Function to display the menu
:display_menu
wsl bash -c 'clear'
echo Choose an option:
echo 1. Setup WSL Environment
echo 2. Start VM
echo 3. Stop VM
echo 4. Destroy VM
echo 5. SSH into VM
echo 6. Exit
set /p choice=Enter choice:
goto process_choice

:: Function to process the menu choice
:process_choice
if "%choice%"=="1" goto setup_wsl
if "%choice%"=="2" goto start_vm
if "%choice%"=="3" goto stop_vm
if "%choice%"=="4" goto destroy_vm
if "%choice%"=="5" goto ssh_vm
if "%choice%"=="6" goto exit_script
echo Invalid choice!
goto display_menu

:: Function to setup the WSL environment
:setup_wsl
wsl bash -c 'clear'
wsl bash -c "echo -e 'This will delete the existing .bashrc file and create a new one with the required environment variables.\nPress any key to continue or Ctrl+C to cancel...'; read -n 1 -s -r -p ''"
if errorlevel 1 goto display_menu
wsl bash -c "cd ~ && if [ -f .bashrc ]; then rm .bashrc; fi && touch .bashrc"
wsl bash -c "echo 'export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1' >> ~/.bashrc"
wsl bash -c "echo 'export PATH=\$PATH:/mnt/c/Program\\ Files/Oracle/VirtualBox' >> ~/.bashrc"
wsl bash -c "echo 'export PATH=\$PATH:/mnt/c/HashiCorp/Vagrant/bin' >> ~/.bashrc"
wsl bash -c "source ~/.bashrc"
echo WSL environment setup completed. Restarting WSL...
wsl --shutdown
timeout /t 3
wsl bash -c "echo -e 'WSL restarted.\nPress any key to continue...'; read -n 1 -s -r -p ''"
goto display_menu

:: Function to start the VM and SSH into it
:start_vm
wsl bash -c 'clear'
wsl bash -c 'echo -e "Starting the VM...\n"'

:: Start the VM and check for errors
wsl bash -c "source ~/.bashrc && vagrant up"
if %ERRORLEVEL% equ 0 (
    :: Copy the SSH key from the VM to the WSL
    wsl bash -c "vagrant ssh-config | grep IdentityFile | awk '{print \$2}' | xargs -I {} cp {} ~/.ssh/private_key"
    wsl bash -c "chmod 600 ~/.ssh/private_key"
)

pause
goto display_menu

:: Function to stop the VM
:stop_vm
wsl bash -c "source ~/.bashrc && vagrant halt"
pause
goto display_menu

:: Function to destroy the VM
:destroy_vm
wsl bash -c "source ~/.bashrc && vagrant destroy -f"
pause
goto display_menu

:: Function to SSH into the VM
:ssh_vm
wsl bash -c "source ~/.bashrc && vagrant ssh"
goto display_menu

:: Function to exit the script
:exit_script
exit /b
