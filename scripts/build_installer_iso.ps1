#Requires -Version 5.0
<#
Windows-native equivalent of build_installer_iso.sh, for hosts without genisoimage
(e.g. a Windows host running the guest in VMware Workstation instead of QEMU/KVM).
Builds minecraft_installer.iso using the built-in IMAPI2FS COM API - no extra
tools (no Windows ADK / oscdimg) required.
#>

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $RepoRoot

try {
    # Verify required files exist
    if (-not (Test-Path "downloads\openjdk.zip") -or -not (Test-Path "downloads\server.jar") `
        -or -not (Test-Path "downloads\plugins\BlockReplacer-1.0.0.jar") -or -not (Test-Path "downloads\plugins\Teleport-1.0.0.jar")) {
        Write-Error "Required downloads not found. Run download_resources.sh first."
        exit 1
    }

    # Create staging directory
    $StagingDir = "iso_staging"
    if (Test-Path $StagingDir) {
        Remove-Item -Recurse -Force $StagingDir
    }
    New-Item -ItemType Directory -Path "$StagingDir\plugins" -Force | Out-Null

    # Copy resources to staging
    Copy-Item "downloads\openjdk.zip" "$StagingDir\" -Force
    Copy-Item "downloads\server.jar" "$StagingDir\" -Force
    Copy-Item "downloads\plugins\*.jar" "$StagingDir\plugins\" -Force

    # Create the Windows setup batch file
    $SetupBat = @'
@echo off
echo Setting up Minecraft server...

mkdir C:\minecraft
cd /d C:\minecraft

echo Extracting Java...
powershell -Command "Expand-Archive -Path '%~dp0openjdk.zip' -DestinationPath 'C:\minecraft\java_temp' -Force"

for /d %%i in (C:\minecraft\java_temp\*) do (
    move "%%i" C:\minecraft\java
)
rd /s /q C:\minecraft\java_temp

echo Copying server files...
copy "%~dp0server.jar" C:\minecraft\server.jar

echo Copying plugins...
mkdir C:\minecraft\plugins
copy "%~dp0plugins\*.jar" C:\minecraft\plugins\

echo Accepting EULA...
echo eula=true>C:\minecraft\eula.txt

echo Disabling online mode verification...
echo online-mode=false>C:\minecraft\server.properties

echo Adding Windows Firewall exception for port 25565...
netsh advfirewall firewall add rule name="Minecraft Server" dir=in action=allow protocol=TCP localport=25565

echo Creating startup script...
(
echo @echo off
echo C:\minecraft\java\bin\java.exe -Dcom.sun.jndi.ldap.object.trustURLCodebase=true -Djdk.jndi.object.factoriesFilter=* -Djdk.jndi.ldap.object.factoriesFilter=* -Xmx8G -Xms8G -jar C:\minecraft\server.jar nogui
) > C:\minecraft\run_server.bat

echo Setup finished.
echo Run C:\minecraft\run_server.bat to start the server.
pause
'@
    Set-Content -Path "$StagingDir\setup_server.bat" -Value $SetupBat -Encoding ASCII

    # Build ISO image using the built-in IMAPI2FS COM API
    function New-DataIso {
        param(
            [Parameter(Mandatory)][string]$SourceDir,
            [Parameter(Mandatory)][string]$IsoPath,
            [string]$VolumeName = "untitled"
        )

        if (!('ISOFile' -as [type])) {
            Add-Type -CompilerParameters (New-Object System.CodeDom.Compiler.CompilerParameters -Property @{ CompilerOptions = '/unsafe' }) -TypeDefinition @'
public class ISOFile
{
    public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)
    {
        int bytes = 0;
        byte[] buf = new byte[BlockSize];
        var ptr = (System.IntPtr)(&bytes);
        var o = System.IO.File.OpenWrite(Path);
        var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;

        if (o != null) {
            while (TotalBlocks-- > 0) {
                i.Read(buf, BlockSize, ptr);
                o.Write(buf, 0, bytes);
            }
            o.Flush();
            o.Close();
        }
    }
}
'@
        }

        $Image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
        $Image.VolumeName = $VolumeName
        # ISO9660 (1) + Joliet (2): preserves long filenames like setup_server.bat,
        # equivalent to genisoimage's `-r -J` flags.
        $Image.FileSystemsToCreate = 3

        Get-ChildItem -Path $SourceDir | ForEach-Object {
            $Image.Root.AddTree($_.FullName, $false)
        }

        if (Test-Path $IsoPath) {
            Remove-Item $IsoPath -Force
        }

        $Result = $Image.CreateResultImage()
        $FullIsoPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $IsoPath))
        [ISOFile]::Create($FullIsoPath, $Result.ImageStream, $Result.BlockSize, $Result.TotalBlocks)

        # IMAPI2FS keeps the source files open via the COM objects above; release
        # them (and force a GC pass) so the staging directory can be deleted next.
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Result)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Image)
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }

    Write-Host "Building ISO image..."
    New-DataIso -SourceDir $StagingDir -IsoPath "minecraft_installer.iso" -VolumeName "MC_INSTALL"

    # Clean up staging directory
    Remove-Item -Recurse -Force $StagingDir

    Write-Host "ISO image built successfully: minecraft_installer.iso"
}
finally {
    Pop-Location
}
