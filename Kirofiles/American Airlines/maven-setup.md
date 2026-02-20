# Maven Setup for NXOP Projects

## Overview

This document provides step-by-step instructions to set up Apache Maven on your local computer for NXOP (Next Gen Operations Platform) projects. Proper Maven configuration ensures reliable dependency resolution from American Airlines' package repositories.

## Prerequisites

- **OpenJDK**: Version 21 or higher installed
- **Maven**: Version 3.9.x or higher installed

### Verify Installation

Open a terminal or command prompt and verify your installations:

```bash
# Check Java version
java -version

# Check Maven version
mvn -version
```

Expected output should show Java 21+ and Maven 3.9+.

## Maven Configuration

### 1. Locate or Create settings.xml

Maven settings are configured in the `settings.xml` file, located in one of these locations:

- **Global**: `$MAVEN_HOME/conf/settings.xml` (affects all users)
- **User-specific**: `~/.m2/settings.xml` (recommended for individual setup)

If the file doesn't exist in `~/.m2/`, create it:

```bash
# Create .m2 directory if it doesn't exist
mkdir -p ~/.m2

# Create settings.xml file
touch ~/.m2/settings.xml
```

### 2. Configure Repository Settings

Open the `settings.xml` file in a text editor and add the following configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings
        xmlns="http://maven.apache.org/SETTINGS/1.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
    
    <pluginGroups>
        <pluginGroup>org.sonarsource.scanner.maven</pluginGroup>
    </pluginGroups>

    <profiles>
        <profile>
            <id>cloudsmith</id>
            <!-- Enable snapshots for the built in central repo to direct -->
            <!-- all requests to cloudsmith via the mirror -->
            <repositories>
                <repository>
                    <id>central</id>
                    <url>https://central</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                </repository>
                <repository>
                    <id>american-airlines-prod</id>
                    <url>${package.manager.prod.repo}</url>
                    <releases>
                        <enabled>true</enabled>
                        <updatePolicy>never</updatePolicy>
                    </releases>
                </repository>
            </repositories>
            <pluginRepositories>
                <pluginRepository>
                    <id>central</id>
                    <url>https://central</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                </pluginRepository>
            </pluginRepositories>
            <properties>
                <!-- These are for pulling dependencies from the cloudsmith repo -->
                <package.manager.prod.repo>https://package-manager.aa.com/basic/prod/maven/</package.manager.prod.repo>
            </properties>
        </profile>
    </profiles>
    
    <activeProfiles>
        <activeProfile>cloudsmith</activeProfile>
    </activeProfiles>

    <servers>
        <server>
            <id>central</id>
            <username>YOUR-PERSONAL-ID</username>
            <password>YOUR-ACCESS-TOKEN</password>
        </server>
        <server>
            <id>cloudsmith</id>
            <username>YOUR-PERSONAL-ID</username>
            <password>YOUR-ACCESS-TOKEN</password>
        </server>
        <server>
            <id>american-airlines-prod</id>
            <username>YOUR-PERSONAL-ID</username>
            <password>YOUR-ACCESS-TOKEN</password>
        </server>
    </servers>

    <mirrors>
        <mirror>
            <id>central</id>
            <mirrorOf>central</mirrorOf>
            <name>maven-public</name>
            <url>https://package-manager.aa.com/basic/prod/maven/</url>
            <!-- If you use this settings.xml, all your builds will try to download dependencies from the above URL.
            If you want your build to look in some other places, then include those URL's in your pom.xml under
            the repositories section. Use one of the <id></id> server names above as an id -->
        </mirror>
    </mirrors>
</settings>
```

### 3. Configure IDE to Use Same Settings

Ensure your IDE (IntelliJ IDEA, Eclipse, etc.) uses the same Maven settings file:

![Maven Settings in IDE](images/ide-maven-settings.png)

**For IntelliJ IDEA:**
1. Go to `File` > `Settings` > `Build, Execution, Deployment` > `Build Tools` > `Maven`
2. Set "User settings file" to point to your `~/.m2/settings.xml`
3. Click "Apply" and "OK"

## Getting Your Access Token

### Cloudsmith Authentication

Follow these steps to obtain your personal credentials for Maven configuration:

#### Step 1: Access Cloudsmith
1. Go to [Cloudsmith Login](https://cloudsmith.io/user/login/)
2. Select **SAML SSO**

![Cloudsmith SAML Login](images/cloudsmith-login.png)

#### Step 2: Organization Login
3. Type `american-airlines` in the Organization field
4. Click "Continue" and login with your AA credentials

![Cloudsmith Organization](images/cloudsmith-login-step2.png)

#### Step 3: Get Personal ID
4. Your **YOUR-PERSONAL-ID** will be shown in the right dropdown option

![Cloudsmith Personal ID](images/cloudsmith-personal-id.png)

#### Step 4: Access API Settings
5. Click on your profile dropdown and select "API Settings"

![Cloudsmith API Settings](images/cloudsmith-api-settings.png)

#### Step 5: Copy API Key
6. Copy the API Key - this will be used as **YOUR-ACCESS-TOKEN**

![Cloudsmith API Key](images/cloudsmith-api-key.png)

#### Step 6: Update settings.xml
7. Replace the placeholder values in your `settings.xml`:
   - Replace `YOUR-PERSONAL-ID` with your actual personal ID from step 4
   - Replace `YOUR-ACCESS-TOKEN` with your API key from step 6

## Testing Your Configuration

### 1. Test Dependency Resolution

Create a simple test to verify your Maven configuration:

```bash
# Create a temporary test directory
mkdir maven-test && cd maven-test

# Generate a simple Maven project
mvn archetype:generate -DgroupId=com.aa.test -DartifactId=maven-test -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

# Navigate to the project
cd maven-test

# Test dependency resolution
mvn clean compile
```

### 2. Build NXOP Project

For existing NXOP projects:

```bash
# Navigate to your project root
cd /path/to/your/nxop-project

# Clean and build the project
mvn clean install

# Run tests
mvn test

# Generate dependency tree (to verify repositories)
mvn dependency:tree
```

### 3. Verify Repository Access

Check that Maven is using the correct repositories:

```bash
# Show effective settings
mvn help:effective-settings

# Show effective POM (including repositories)
mvn help:effective-pom
```

---

**Note**: This document should be updated when repository URLs, authentication methods, or organizational policies change.
