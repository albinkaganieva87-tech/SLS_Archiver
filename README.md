# SLS_Archiver
Zip archiver, but it is sls. sus linked archive...
# Release notes:
* add archivizer and dearchivizer
* add assotiation manager from windows reg if you want it
# Info:
* Langs: Win: VBS, windows PowerShell 5, Lin/MacOS: Bash
* Created: by Sus Imposter Studios
* Version: 1.2.0
# Fixed bug in windiws version
in other edition program can fall here: 
```powershell
catch { 
    ф `
    -Activity "Распаковка"  
    -Completed `
```
now we fixed it:

```powershell
catch { 

    Write-Progress `
        -Activity "Распаковка" `
        -Completed
```
