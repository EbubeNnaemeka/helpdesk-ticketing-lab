# Ticket guide

What each scenario is testing and where to start. Work the ticket first; read this only if stuck. Fixes are applied in the [Active Directory lab](https://github.com/EbubeNnaemeka/active-directory-lab) (domain `corp.lab`) and the [Windows desktop support lab](https://github.com/EbubeNnaemeka/windows-desktop-support-lab).

| Ticket | What it tests | Where to start |
|---|---|---|
| T01 Locked out after password change | Lockout vs wrong password; stale credentials on a second device | `Get-ADUser -Properties LockedOut,BadLogonCount`; Event ID 4740 on the DC shows the source machine; unlock, then find the device still using the old password (phone mail, mapped drive, saved RDP) |
| T02 Forgot password | Identity verification before reset | Verify the caller per policy (callback to number on file, manager confirmation) **before** `Set-ADAccountPassword -Reset`; set "change at next logon" |
| T03 New hire | Onboarding checklist | Create user in the right OU, Sales groups, home/shared drive access; confirm start date; send credentials securely, not in the ticket |
| T04 Leaver | Offboarding and timing | Schedule for Friday 17:00: disable account, reset password, remove groups, move to Disabled OU, set mail forwarding to manager; record what was done for audit |
| T05 Missing Finance drive | Group membership vs Group Policy | Is she still in the Finance group (`Get-ADPrincipalGroupMembership`)? `gpresult /r` on her PC; `gpupdate /force`; check the drive-map GPO's item-level targeting |
| T06 3rd floor printer | Shared printer, many users | Several users affected = higher impact. Check the print server queue, restart spooler on the server, clear stuck jobs; confirm with a test page |
| T07 Outlook password prompts | Cached credentials / modern auth | Credential Manager entries for Office, sign out of Office and back in, check for a recent password change (links to T01) |
| T08 Slow laptop | Structured performance triage | Task Manager (CPU, memory, disk), startup apps, free disk space, pending updates, uptime; `Get-SystemHealth.ps1` from the desktop lab |
| T09 No internet on desktop | Bottom-up network troubleshooting | Link light, `ipconfig /all` (APIPA 169.254.x.x = DHCP problem), ping gateway, ping 8.8.8.8, `nslookup`; isolates cable vs DHCP vs DNS |
| T10 Sales can't reach CRM | Major incident handling | Many users + business impact = raise priority, notify the team, find the common factor (DNS record? firewall? vendor outage?), post updates every 30 minutes |
| T11 Disk full | Safe cleanup | Storage Sense, `cleanmgr`, find large folders (Downloads, temp, old OST files); never delete user data without asking |
| T12 Windows updates failing | Error-code research | 0x80070002 = missing files; run `DISM /RestoreHealth`, `sfc /scannow`, reset Windows Update components |
| T13 Install Acrobat | Request approval and licensing | Check approval and license availability first; install from the approved package, not a web download |
| T14 Phishing link clicked | Security incident response | Treat as High. Ask exactly what was entered; reset password and revoke sessions as a precaution, report the email, check for the same message in other mailboxes, escalate to security |
| T15 Lost MFA phone | Identity verification + MFA reset | Verify identity strongly (it's a classic social-engineering pretext), then reset MFA registration and issue a temporary access method |
| T16 Monitor flickering | Hardware isolation | Swap the cable, try another port, test the monitor on another PC; update display driver; replace if the fault follows the monitor |
| T17 VPN timeout | Home network vs VPN service | Can she reach the internet? Is the VPN service up for others? Check client version, time sync, home router blocking UDP |
| T18 Teams audio | App-specific device settings | Teams device settings (wrong mic selected), Windows privacy setting for microphone access, test call |
| T19 Temporary profile | Corrupt profile recovery | Event ID 1511/1515; check `HKLM\...\ProfileList` for a `.bak` key; back up data before rebuilding the profile |
| T20 Department transfer | Access change (least privilege) | Remove Sales groups **and** add Marketing groups; update department attribute; check the OU move doesn't break GPOs he still needs |
| T21 Shared mailbox | Microsoft 365 admin | Create in the M365 admin center / Exchange admin center, grant Full Access + Send As to the 4 users ([m365-intune-lab](https://github.com/EbubeNnaemeka/m365-intune-lab)) |
| T22 BitLocker recovery | Recovery key retrieval + verification | Verify identity, get the key from AD/Entra ID by key ID, read it to the user; explain the BIOS update triggered it |
| T23 Print spooler | Service troubleshooting | Spooler service stopped or crashing: clear `C:\Windows\System32\spool\PRINTERS`, restart service, check Event Viewer |
| T24 Blocked website | Policy, not a fault | Category blocked by policy: explain, route the request to the firewall/security owner for approval; don't bypass it |
| T25 Second monitor | Hardware request | Check stock and approval, schedule install, update the asset record in GLPI (Assets > Monitors) |
