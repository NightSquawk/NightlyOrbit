@echo off
setlocal enabledelayedexpansion

:: Launch the Docker container using Docker Compose
docker-compose up -d --build

:: Get the container ID or name
for /f "tokens=1" %%i in ('docker ps') do (
    set CONTAINER_ID=%%i
)

:: Check if the container ID was retrieved successfully
if not defined CONTAINER_ID (
    echo Failed to retrieve the container ID.
    exit /b 1
)

:: Execute a bash shell inside the container using winpty
docker exec -it %CONTAINER_ID% bash
