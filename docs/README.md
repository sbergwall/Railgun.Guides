# Railgun.Guides

A collection of deployment and configuration guides for enterprise infrastructure components.

## Table of Contents

### Core Infrastructure
1. [Install First Domain Controller](01.%20Install-First-Domain-Controller.md)
   - Initial AD forest setup
   - Domain configuration
   - OU structure creation

2. [Windows Admin Center](02.%20Install-Windows-Admin-Center.md)
   - Installation and configuration
   - Extension management
   - Security setup
   - Post-installation tasks

### Client Management
3. [Windows 11 Client Deployment](03.%20Install-Windows-11-Client.md)
   - Prerequisites and requirements
   - VM creation
   - OS installation
   - Software deployment
   - Domain joining

4. [Local Administrator Password Solution](04.%20Configure-LAPS.md)
   - Tiered access model integration
   - Security group configuration
   - Password policy setup
   - Client deployment
   - Maintenance, auditing, troubleshooting, and GPO best practices
   - Custom admin account creation
   - Supported OS and update requirements

### Database Infrastructure
5. [SQL Server Installation and Configuration](xx-Install-SQL-Server.md)
   - Disk and OS preparation
   - Service account creation
   - Automated installation with DBAtools
   - Post-installation best practices
   - Maintenance and monitoring
   - [SQL Server Checklist](Checklist-SQLServer.md)

### Application Infrastructure
- SharePoint Server Subscription Edition
- Exchange Server 2019
- Windows Event Collector
- File Server Setup

## Repository Structure

- Numbered files (e.g., `01.`, `02.`) represent the recommended deployment order
- PowerShell scripts (`.ps1`) contain automation for deployments
- Markdown files (`.md`) contain detailed documentation and procedures
- `xx-` prefixed files are in draft status or pending reorganization

## Getting Started

1. Start with [Install First Domain Controller](01.%20Install-First-Domain-Controller.md)
2. Deploy [Windows Admin Center](02.%20Install-Windows-Admin-Center.md)
3. Configure [Windows 11 clients](03.%20Install-Windows-11-Client.md)
4. Implement [LAPS](04.%20Configure-LAPS.md)
5. Install and configure [SQL Server](xx-Install-SQL-Server.md)
6. Continue with specific infrastructure components as needed

## Contributing

Please read the CHANGELOG.md file for details on our versioning and release history.

## SharePoint Components
- SharePoint Server farm configuration
- Service applications setup
- Web applications deployment

## Development Tools
- PowerShell Universal (PSU) setup