# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible receiving such patches depend on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within Skill Writer, please send an email to security@skill-writer.org. All security vulnerabilities will be promptly addressed.

**Please do not report security vulnerabilities through public GitHub issues.**

### What to Include

When reporting a vulnerability, please include:

1. **Description**: Clear description of the vulnerability
2. **Impact**: What could be compromised
3. **Steps to Reproduce**: Detailed steps to reproduce the issue
4. **Affected Versions**: Which versions are affected
5. **Proof of Concept**: If available, provide a PoC
6. **Suggested Fix**: If you have suggestions for fixing

### Response Timeline

| Phase | Timeline |
|-------|----------|
| Acknowledgment | Within 48 hours |
| Initial Assessment | Within 1 week |
| Fix Development | Depends on severity |
| Disclosure | After fix is released |

### Severity Levels

- **Critical (CVSS 9.0-10.0)**: Immediate response, fix within 7 days
- **High (CVSS 7.0-8.9)**: Urgent response, fix within 30 days
- **Medium (CVSS 4.0-6.9)**: Standard response, fix within 90 days
- **Low (CVSS 0.1-3.9)**: Planned response, fix in next release

## Security Scanning

Our project undergoes regular security scanning for the following vulnerability categories:

### CWE-798: Use of Hard-coded Credentials
We scan for:
- Hard-coded passwords or API keys
- Default credentials
- Exposed secrets in configuration files

### CWE-89: SQL Injection
We scan for:
- Unparameterized SQL queries
- Dynamic query construction
- User input in SQL statements

### CWE-78: OS Command Injection
We scan for:
- Unsanitized user input in system calls
- Shell command construction
- Process execution vulnerabilities

### CWE-22: Path Traversal
We scan for:
- Unsanitized file paths
- Directory traversal sequences
- File access vulnerabilities

## Security Best Practices

### For Users

1. **Keep Updated**: Always use the latest stable version
2. **Review Dependencies**: Regularly audit your dependencies
3. **Enable Security Features**: Use available security configurations
4. **Report Issues**: Report any suspicious behavior immediately

### For Contributors

1. **Input Validation**: Always validate and sanitize user input
2. **Secure Defaults**: Use secure default configurations
3. **Least Privilege**: Follow principle of least privilege
4. **Dependency Management**: Keep dependencies updated
5. **Code Review**: All code must be reviewed before merging

## Security Tools

We use the following tools for security:

- **Dependabot**: Automated dependency updates
- **CodeQL**: Static analysis for security vulnerabilities
- **Snyk**: Dependency vulnerability scanning
- **GitHub Security Advisories**: Security issue tracking

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the vulnerability and determine affected versions
2. Audit code to find any similar problems
3. Prepare fixes for all supported versions
4. Release new versions as soon as possible
5. Publicly disclose the issue after patches are available

## Acknowledgments

We would like to thank the following security researchers who have responsibly disclosed vulnerabilities:

- [Your name here] - [Vulnerability description]

## Contact

- **Email**: security@skill-writer.org
- **GPG Key**: [Download public key]
- **Slack**: #security channel

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [GitHub Security Lab](https://securitylab.github.com/)
