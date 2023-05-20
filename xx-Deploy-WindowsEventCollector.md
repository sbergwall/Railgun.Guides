
## Configure the Collector Server
Start Event Viewer and go to Subscriptions. Click Yes when asked if we want to work with subscriptions. This will configure and start the needed services.

Start Windows Powershell as and admin

```powershell
winrm quickconfig -quiet # Configure WinRM
Set-Service -Name WINRM -StartupType Automatic # Start WinRM at startup
wevtutil sl forwardedevents /ms:1000000000 # Configure Event Forwarding
```

For Event Collector to work with both 2019 and 2016 we need to start CMD as Admin. This will fix some of the ACL that has been changed in 2019.

```cmd
netsh http delete urlacl url=http://+:5985/wsman/
netsh http add urlacl url=http://+:5985/wsman/ sddl=D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)
netsh http delete urlacl url=https://+:5986/wsman/
netsh http add urlacl url=https://+:5986/wsman/ sddl=D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)
```

In Event Viewer right click on Subscriptions and select ''Create Subscritpion''. Select ''Source computer initiated'' so the servers will send the logs to Event Collector, instead of the Event Collector reaching out to the servers for collection.
Click Select Computer Groups and add the servers you want to send event to the Collector.

Click Select Events and the XML tab. Click Edit query manually. For a baseline config go to https://raw.githubusercontent.com/HASecuritySolutions/Logstash/master/event_collector_events Go to Advanced and select Minimize latency.
The Collector is now ready to receive events.

## Configure Group Policy
Open Group Policy Management and create a new GP. Go to Computer Configureation > Polocies > Windows Settings > Security Settings > Restricted Groups. Right click and select Add group. Add the NT AUTHORITY\Network Service.
Go to System Services and set Windows remote Management to Automatic.

Go to Administrative Templates > Windows Components> Event Forwarding and edit Configure fowarder resource usage. Enable it and choose between 100-500. 500 is for Production.
Edit Configure target Subscrition Manager and click Enabled. Under SubscriptionManagers click SHow. Add 'Server=http://wec01.company.pri:5985/wsman/SubscriptionManager/WEC.Refresh=120'

Go to Event Log Service and Security. Edut Configure log access, Enable it and add 'O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;S-1-5-20)' without '' and the beginning at the end,  to Log Access.
The GP is done. 

In the Collector, go to Subscription agan and see if there is any new Source Computers. If there isnt any we can force a GP Update on the servers with 'GPUpdate /force'. This will refresh the polocies.


