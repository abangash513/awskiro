# Java Coding Standards - NXOP Projects

## Overview

This document defines the Java coding standards for NXOP (Next Gen Operations Platform) projects within American Airlines. These standards ensure code consistency, readability, and maintainability across all Java-based applications.

## Code Style Guide

### Google Java Style Guide

NXOP projects follow the **Google Java Style Guide** as the primary coding standard. This provides:

- Consistent formatting across all Java codebases
- Industry-standard best practices
- Automated tooling support
- Clear readability guidelines

## Setting Up IntelliJ IDEA with Google Java Style Guide

### Step 1: Download the Google Java Style Guide XML

1. Download the Google Java Style Guide XML file from the official repository:
   - [intellij-java-google-style.xml](https://github.com/google/styleguide/blob/gh-pages/intellij-java-google-style.xml)
   - Right-click and save the file to your local machine

### Step 2: Import the Style Guide into IntelliJ IDEA

1. Open IntelliJ IDEA
2. Go to `File` > `Settings` (or `IntelliJ IDEA` > `Preferences` on macOS)
3. In the Settings/Preferences dialog, navigate to `Editor` > `Code Style`
4. Click on the gear icon next to the `Scheme` dropdown and select `Import Scheme` > `IntelliJ IDEA code style XML`
5. Select the downloaded `intellij-java-google-style.xml` file and click `Open`
6. The Google Java Style Guide will be imported and applied to your project

### Step 3: Apply the Style Guide to Your Project

1. In the `Code Style` settings, select the imported Google Java Style Guide from the `Scheme` dropdown
2. Click `Apply` and then `OK` to save the changes

### Step 4: Configure Actions on Save (Recommended)

To automatically format code when saving files:

1. Go to `File` > `Settings` > `Tools` > `Actions on Save`
2. Enable the following options:
   - ✅ **Reformat code**
   - ✅ **Optimize imports**
   - ✅ **Rearrange code** (optional)

![IntelliJ Save Actions Configuration](images/intellij-save-actions.png)

### Javadoc Requirements

All public classes, interfaces, and methods must have Javadoc comments:

```java
/**
 * Processes flight data from various sources and updates the flight status.
 * 
 * <p>This service handles real-time flight updates from ACARS, gate systems,
 * and schedule management systems. It ensures data consistency and triggers
 * appropriate notifications for flight status changes.
 * 
 * @author NXOP Team
 * @since 1.0.0
 */
@Service
public class FlightDataProcessor {
    
    /**
     * Processes a flight update message and updates the flight status.
     * 
     * @param flightUpdate the flight update message containing new status information
     * @param source the source system that generated the update
     * @return the updated flight object with new status
     * @throws FlightProcessingException if the update cannot be processed
     * @throws IllegalArgumentException if flightUpdate or source is null
     */
    public Flight processFlightUpdate(FlightUpdate flightUpdate, String source) {
        // Implementation
    }
}
```


## Build and Dependency Management

### Maven Configuration

Use Maven for dependency management with the following standards:

```xml
<!-- Parent POM for NXOP projects -->
<parent>
    <groupId>com.aa.nxop</groupId>
    <artifactId>nxop-parent</artifactId>
    <version>1.0.0</version>
</parent>


<!-- Properties -->
<properties>
    <java.version>21</java.version>
    <maven.compiler.source>21</maven.compiler.source>
    <maven.compiler.target>21</maven.compiler.target>
</properties>
```


## Checklist for Code Reviews

### Before Submitting Code

- [ ] Code follows Google Java Style Guide
- [ ] All public methods have Javadoc
- [ ] Unit tests are written and passing
- [ ] No hardcoded values (use configuration)
- [ ] Proper exception handling implemented
- [ ] No code smells or warnings

### During Code Review

- [ ] Code is readable and well-documented
- [ ] Business logic is clear and correct
- [ ] Error handling is appropriate
- [ ] Tests cover edge cases
- [ ] Performance considerations addressed
- [ ] Security vulnerabilities checked


---

**Note**: This document should be reviewed and updated regularly as the project evolves and new best practices emerge.
