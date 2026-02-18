# windoze-jdk

A lightweight PowerShell utility for installing and switching between JDK versions on Windows. Uses [Adoptium Temurin](https://adoptium.net/) builds and persists your selection across terminal sessions.

## Supported Versions

- Java 8
- Java 17
- Java 21

## Requirements

- Windows with PowerShell
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (included on Windows 10 1709+ and Windows 11) — only needed for the `-Install` flag
- Administrator privileges when installing a JDK via winget

## Usage

### Switch to an already-installed JDK

```powershell
.\jdk-switch.ps1 21
.\jdk-switch.ps1 17
.\jdk-switch.ps1 8
```

### Install a JDK and switch to it

```powershell
.\jdk-switch.ps1 21 -Install
.\jdk-switch.ps1 17 -Install
.\jdk-switch.ps1 8 -Install
```

The `-Install` flag will use winget to install the specified Adoptium Temurin JDK if it isn't already present, then activate it.

## What It Does

1. Looks for the requested JDK under `C:\Program Files\Eclipse Adoptium`
2. If not found and `-Install` is provided, installs it via winget
3. Updates `JAVA_HOME` and `PATH` at the **User** scope so the change persists across new terminal sessions
4. Cleans out any previous Adoptium JDK paths to avoid conflicts
5. Verifies the switch by printing the active Java version

## Example Output

```
Found JDK 21 at: C:\Program Files\Eclipse Adoptium\jdk-21.0.3+9

JAVA_HOME = C:\Program Files\Eclipse Adoptium\jdk-21.0.3+9
Active:     openjdk version "21.0.3" 2024-04-16 LTS

Switched to JDK 21. New terminals will use this version.
```
