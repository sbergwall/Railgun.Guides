# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-07-05

### Added
- Major cleanup and reorganization of documentation
- New and improved SQL Server installation and configuration guide (`xx-Install-SQL-Server.md`)
- Expanded WSUS, LAPS, and Windows 11 deployment documentation
- Improved troubleshooting and maintenance sections for all major guides

### Changed
- Updated all domain and OU references to `company.pri` and `company`
- Standardized naming and structure across all guides
- Updated README Table of Contents to reflect current file set
- Clarified and expanded best practices in SQL Server, WSUS, and LAPS guides

### Removed
- Deprecated and draft files no longer needed
- Old/duplicate SQL Server, Windows 11, and LAPS guides
- Unneeded scripts and documentation for legacy infrastructure

## [1.0.1] - 2025-05-24

### Added
- Comprehensive Windows Admin Center 2410 installation guide
- Updated WAC deployment best practices and security considerations
- Troubleshooting section for WAC installation
- New LAPS deployment guide with tiered access model support
- Windows 11 client deployment guide with modern requirements

### Changed
- Consolidated WAC installation guides into a single document
- Updated WAC version information to 2410 (April 2024)
- Restructured LAPS documentation to align with enterprise tiering model
- Improved security considerations for LAPS deployment
- Reorganized guides with proper numbering scheme

### Removed
- Deprecated xx-Deploy-Win11.md in favor of new Windows 11 guide
- Enhanced prerequisites section with detailed requirements

### Removed
- Duplicate WAC installation guide
- Initial documentation structure
- Hyper-V VM creation scripts for servers and clients
- Domain Controller installation and configuration guide
- Windows Admin Center (WAC) server setup
- LAPS configuration guide
- SQL Server deployment guides
- Exchange Server 2019 installation guide
- SharePoint Server Subscription Edition deployment guides
- Windows Event Collector setup
- PowerShell Universal (PSU) installation guide
- File Server deployment documentation
- Comprehensive Active Directory tiered security model implementation
