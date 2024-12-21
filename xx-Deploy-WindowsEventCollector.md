# Windows Event Collector Setup Guide

This guide explains how to set up a Windows Event Collector (WEC) to centralize log collection. It includes best practices, configuration steps for the collector server, group policy setup, and troubleshooting. Additionally, we cover Sysmon installation for advanced event monitoring.

---

## Best Practices

1. **Scalability**: A single collector server should manage no more than 2000–3000 assets to ensure performance and reliability.
2. **Log Storage**: In Event Viewer, right-click on **Forwarded Events**, select **Properties**, and set the **Maximum log size (KB)** to at least 4 GB to prevent log truncation.

For more detailed performance tuning, consult the [Microsoft documentation](https://learn.microsoft.com/en-us/troubleshoot/windows-server/admin-development/configure-eventlog-forwarding-performance).

---

## Configuring the Collector Server

1. **Enable Subscriptions in Event Viewer**:
   - Open **Event Viewer**.
   - Go to **Subscriptions**. When prompted, click **Yes** to configure and start the necessary services.

2. **Enable and Configure WinRM**:
   - Open **Windows PowerShell** as an Administrator and run:
     ```powershell
     winrm quickconfig -quiet  # Enable and configure WinRM.
     Set-Service -Name WINRM -StartupType Automatic  # Ensure WinRM starts at boot.
     wevtutil sl forwardedevents /ms:1000000000  # Set Forwarded Events log size to ~1GB.
     ```

3. **Fix ACL Issues for Compatibility (Windows Server 2016/2019)**:
   - Open **Command Prompt** as Administrator and run:
     ```cmd
     netsh http delete urlacl url=http://+:5985/wsman/
     netsh http add urlacl url=http://+:5985/wsman/ sddl=D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)
     netsh http delete urlacl url=https://+:5986/wsman/
     netsh http add urlacl url=https://+:5986/wsman/ sddl=D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)
     ```

4. **Create a Subscription**:
   - In **Event Viewer**, right-click **Subscriptions** and select **Create Subscription**.
   - Choose **Source computer-initiated** to have servers send logs to the collector.
   - **Add Computer Groups**: Click **Select Computer Groups** and add the target servers.
   - **Select Events**:
     - Switch to the **XML** tab and select **Edit query manually**.
     - For a baseline configuration, use [this event filter](https://raw.githubusercontent.com/HASecuritySolutions/Logstash/master/event_collector_events).
   - Go to **Advanced** and select **Minimize latency**.

---

## Configuring Group Policy for Forwarders

1. **Set Event Log Readers Group**:
   - Navigate to **Computer Configuration** > **Policies** > **Windows Settings** > **Security Settings** > **Restricted Groups**.
   - Add a group named **Event Log Readers**.
   - In the **Member of this group** section, add **NT AUTHORITY\Network Service**.

2. **Enable and Configure WinRM**:
   - Go to **System Services** and set **Windows Remote Management (WinRM)** to **Automatic**.

3. **Configure Event Forwarding Settings**:
   - Navigate to **Administrative Templates** > **Windows Components** > **Event Forwarding**.
   - Edit **Configure forwarder resource usage**:
     - Enable and set to a value between **100-500** (500 is recommended for production).
   - Edit **Configure target Subscription Manager**:
     - Enable and click **Show**. Add:
       ```
       Server=http://wec01.company.pri:5985/wsman/SubscriptionManager/WEC,Refresh=120
       ```

4. **Set Log Access Permissions**:
   - Go to **Event Log Service** > **Security** and edit **Configure log access**:
     - Enable and add the following string:
       ```
       O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;S-1-5-20)
       ```

5. **Force Group Policy Update**:
   - On the target servers, run:
     ```cmd
     gpupdate /force
     ```

---

## Verifying WEF Configuration

1. On the log collector, open **Event Viewer** and go to **Subscriptions**.
2. Confirm that the number of **Source Computers** increases as endpoints check in.
3. Right-click a subscription and select **Runtime Status** to view detailed information about connected endpoints.

---

## Sysmon Configuration and Installation

Sysmon provides advanced event logging capabilities. Follow these steps to configure and install it:

1. **Download and Prepare**:
   - Download Sysmon from [Microsoft Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon).
   - Choose a configuration file from:
     - [Sysmon Modular Configurations](https://github.com/olafhartong/sysmon-modular)
     - [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
     - [Black Hills InfoSec Event Logging](https://github.com/blackhillsinfosec/EventLogging)

2. **Install Sysmon**:
   - Place `Sysmon.exe` and the configuration file in the same directory.
   - Open Command Prompt or PowerShell and run:
     ```cmd
     .\Sysmon.exe -i <path to config> -accepteula
     ```
     Example:
     ```cmd
     .\Sysmon.exe -i .\sysmonconfig-export.xml -accepteula
     ```

---

## Additional Resources

- [Windows Event Forwarding and Event Collectors In-Depth (YouTube)](https://www.youtube.com/watch?v=gUOl82434Ic)
- [BHIS | Intro to Windows Event Collecting (YouTube)](https://www.youtube.com/watch?v=Eix5BPta56E)
- [Step-by-Step Guide to Windows Event Forwarding and NTLMv1 Monitoring](https://michaelwaterman.nl/2024/06/29/step-by-step-guide-to-windows-event-forwarding-and-ntlmv1-monitoring/)
