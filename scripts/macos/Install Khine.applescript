-- One-click installer placed beside Khine.app on the macOS DMG.
on run
	set installerPath to POSIX path of (path to me)
	set dmgRoot to do shell script "dirname " & quoted form of installerPath

	set sourceApp to dmgRoot & "/Khine.app"
	set targetApp to "/Applications/Khine.app"

	try
		do shell script "test -d " & quoted form of sourceApp
	on error
		display alert "Khine.app was not found next to the installer." buttons {"OK"} default button 1
		return
	end try

	try
		do shell script "rm -rf " & quoted form of targetApp & " && ditto " & quoted form of sourceApp & " " & quoted form of targetApp with administrator privileges
	on error errMsg number errNum
		display alert "Installation failed." message errMsg buttons {"OK"} default button 1
		return
	end try

	try
		do shell script "xattr -cr " & quoted form of targetApp
	end try

	try
		tell application "Finder" to open POSIX file targetApp
	on error
		do shell script "open " & quoted form of targetApp
	end try

	display notification "Khine was installed to Applications." with title "Khine"
end run
