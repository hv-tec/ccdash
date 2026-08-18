-- Claude kasutus — avab ccdash-dashboardi äpiaknana.
-- Kogu loogika on ~/.claude/scripts/ccdash-open sees; see applet on ainult ikoon.
on run
	set launcher to (POSIX path of (path to home folder)) & ".claude/scripts/ccdash-open"
	try
		do shell script quoted form of launcher & " > /dev/null 2>&1 &"
	on error errMsg
		display dialog "Dashboardi ei õnnestunud avada:" & return & return & errMsg ¬
			buttons {"OK"} default button "OK" with icon caution
	end try
end run

