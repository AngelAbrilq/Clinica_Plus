@echo off
REM ============================================================
REM Clinica Plus - Configuracion inicial de Supabase CLI
REM Uso: scripts\setup_supabase.cmd TU_PROJECT_REF
REM ============================================================
if "%~1"=="" (
  echo [ERROR] Falta el project ref. Uso: scripts\setup_supabase.cmd TU_PROJECT_REF
  exit /b 1
)
cd /d "%~dp0.."

echo.
echo [1/4] Inicializando Supabase (crea supabase\config.toml)...
if not exist supabase\config.toml (
  call npx --yes supabase init
  if errorlevel 1 goto :error
) else (
  echo       config.toml ya existe, se omite.
)

echo.
echo [2/4] Iniciando sesion (se abre el navegador)...
call npx --yes supabase login
if errorlevel 1 goto :error

echo.
echo [3/4] Vinculando con el proyecto %~1 (te pedira la contrasena de la BD)...
call npx --yes supabase link --project-ref %~1
if errorlevel 1 goto :error

echo.
echo [4/4] Aplicando migraciones a Supabase...
call npx --yes supabase db push --linked
if errorlevel 1 goto :error

echo.
echo [OK] Base de datos lista.
exit /b 0

:error
echo.
echo [ERROR] Fallo el paso anterior. Copia el mensaje y compartelo.
exit /b 1
