# Security Policy

## Supported Versions

We actively support the following versions of WatchTheFlix with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email security concerns to the repository maintainers privately
3. Provide a detailed description of the vulnerability
4. Include steps to reproduce the issue if possible
5. Allow time for the maintainers to investigate and respond

### What to Include

- Type of vulnerability (e.g., XSS, injection, authentication bypass)
- Location of the affected code (file path, line numbers if known)
- Step-by-step instructions to reproduce
- Potential impact of the vulnerability
- Any suggested fixes (optional but appreciated)

### Response Timeline

- **Initial Response**: Within 48-72 hours
- **Status Update**: Within 7 days
- **Resolution**: Varies based on complexity, typically within 30 days

### Security Best Practices for Contributors

When contributing to WatchTheFlix, please follow these security guidelines:

1. **No Hardcoded Secrets**: Never commit API keys, passwords, or tokens
2. **Input Validation**: Always validate and sanitize user inputs
3. **Secure Dependencies**: Use up-to-date, well-maintained dependencies
4. **Secure Storage**: Use secure storage mechanisms (Hive, SharedPreferences with encryption for sensitive data)
5. **Network Security**: Use HTTPS for all network requests; validate SSL certificates
6. **Error Handling**: Don't expose sensitive information in error messages

### Data Privacy

WatchTheFlix is designed with privacy in mind:

- All playlist data is stored locally on the device
- No user data is transmitted to external servers (except to configured IPTV providers)
- Optional Firebase integration requires explicit configuration
- VPN detection is performed locally

## Security Features

- **Local Storage Only**: Playlists and preferences stored locally
- **No Tracking**: No analytics unless Firebase is explicitly enabled
- **Secure HTTP Client**: Dio with configurable timeouts and headers
- **Input Sanitization**: URL and input validation throughout the app

## Acknowledgments

We appreciate responsible disclosure and will acknowledge security researchers who help improve our security.
