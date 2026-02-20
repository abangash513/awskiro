# Technical Proposal: Standardizing Database Migrations with Liquibase

## Summary

Liquibase is a vendor-agnostic database schema change management solution that supports a wide range of platforms, including Oracle, PostgreSQL, MySQL, MSSql, and MongoDB. To optimize our Java development lifecycle, we have evaluated three primary integration strategies. Based on the need for environmental parity and deployment autonomy, Option 3 (Containerized Migration) is the recommended approach.
## Integration Strategies

| Strategy                                   | Pros                                                                                                                | Cons                                                                                            |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Decoupled Repository & Pipeline            | Independent of application workflows; ideal for dedicated DBA teams                                                 | Tight coupling between app code and schema; requires high cross-team coordination.              |
| Integrated Repository / Dedicated Pipeline | Code and migrations reside in one place; synchronized deployments via build tool plugins (Maven/Gradle)             | Requires CI/CD runners to have direct database access; Complicates ephemeral environment setup. |
| Containerized Migrations (Recommended)     | Full portability; migrations are bundled with the application image. Identical behavior across Local, Dev, and Prod | Marginal increase in container image size and layer count.                                      |
|                                            |                                                                                                                     |                                                                                                 |
## Proof of Concept (PoC) Implementation

A successful PoC of Option 3 has been deployed within the [aot-nxop-flight-subgraph](https://github.com/AAInternal/aot-nxop-flight-subgraph) repo.

### Technical Implementation Details:
-  **Dependency Management:** Liquibase core and drivers are managed via pom.xml, ensuring version consistency with the application stack.
- **Artifact Storage:** Database changelogs are maintained under db/liquibase/changelogs.
- **Execution Logic:** The application’s entrypoint.sh was modified to intercept a `migratedb` argument.
	- If `migratedb` is passed, the container executes the Liquibase migration logic.
	- If `migratedb` is not passed, the container initializes the application normally.
	- With both paths, additional arguments are passed to their respective  applications.

> [!IMPORTANT]
> 
> Only one application/repo should manage changes to shared databases to avoid conflicts. The exception to this is if multiple apps/ repos use the same database but isolated schemas/ collections.
> 

### Kubernetes Orchestration:
To ensure zero-downtime deployments and schema safety, migrations are executed via an initContainer within the deployment specification. This ensures the database schema is updated before the new application version attempts to boot.

> [!NOTE]
>
> The use of an `initContainer` definition within the KPaaS K8S config has not been tested. Our research did not turn up documentation or current apps that have used an initContainer in KPaaS. The functionality of liquibase was validated on the aot-nxop-flight-subgraph application in Development environment by exec in and executing the entrypoint.sh with the `migratedb` arg.
>

[webapp.yaml](https://github.com/AAInternal/aot-nxop-flight-subgraph/blob/697a8ec5fd17066891d032dc3c0e6765dcc49a13/k8s/dev/webapp.yaml)
```yaml
spec:
	initContainers: # Init container is ran to completion before main app container is started
	  - name: db-migration
	    image: flight-subgraph:v0.5.2
	    command: [] ## Use existing entrypoint
	    args: ["migratedb"]
	containers: # App containers start if init container runs and shutsdown cleanly
	  - name:
	    image: flight-subgraph:v0.5.2
	    command: [] ## Use existing entrypoint
	    args: [] 
	
```

[pom.xml Dependency](https://github.com/AAInternal/aot-nxop-flight-subgraph/blob/324377dfefbe6feb493325833c24665d8989394f/pom.xml#L117-L133)
[pom.xml Plugin](https://github.com/AAInternal/aot-nxop-flight-subgraph/blob/324377dfefbe6feb493325833c24665d8989394f/pom.xml#L52-L68)
```xml
  <dependencies>
    <!-- Liquibase -->
    <dependency>
      <groupId>org.liquibase</groupId>
      <artifactId>liquibase-core</artifactId>
      <version>4.33.0</version>
    </dependency>
    <dependency>
      <groupId>org.liquibase.ext</groupId>
      <artifactId>liquibase-mongodb</artifactId>
      <version>4.33.0</version>
    </dependency>
    <dependency>
      <groupId>commons-io</groupId>
      <artifactId>commons-io</artifactId>
      <version>2.11.0</version>
    </dependency>
  </dependencies>
    <!-- Liquibase -->


	<plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.6.0</version>
        <executions>
          <execution>
            <id>copy-dependencies</id>
            <phase>package</phase>
            <goals>
              <goal>copy-dependencies</goal>
            </goals>
            <configuration>
              <outputDirectory>${project.build.directory}/lib</outputDirectory>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>

```

[entrypoint.sh](https://github.com/AAInternal/aot-nxop-flight-subgraph/blob/324377dfefbe6feb493325833c24665d8989394f/entrypoint.sh)
```bash
#!/bin/sh

# Set the application JAR
APP_JAR="app.jar"

# Set Liquibase directory
LIQUIBASE_DIR="/app/db/liquibase"
LIQUIBASE_LIB="$LIQUIBASE_DIR/lib"
LIQUIBASE_CHANGELOG="$LIQUIBASE_DIR/changelog/db.changelog-master.xml"
LIQUIBASE_CONF="$LIQUIBASE_DIR/liquibase.properties"

# Check if the first argument is 'migratedb'
if [ "$1" = "migratedb" ]; then
    echo "Running Liquibase migrations..."
    
    # Construct classpath - include all libs in the liquibase lib directory
    # If the directory is empty or doesn't exist, this might fail, 
    # but we assume the Dockerfile setup is correct.
    CP="$LIQUIBASE_LIB/*:/app"
    

    # Shift the 'migratedb' argument
    shift
    
    # Run Liquibase
    # We pass common parameters. Extra arguments can be passed via command line.
    # The --url should be provided via environment variable (e.g., MONGODB_URI)
    if [ ! -z "$MONGODB_URI" ]; then
    
        echo "Running Liquibase migrations..."
        exec java -cp "$CP" liquibase.integration.commandline.Main \
            --changelog-file="$LIQUIBASE_CHANGELOG" \
            --url="${MONGODB_URI}" \
            update "$@"
    elif [ ! -z "$DOCUMENTDB_HOST" ]; then
        echo "Running Liquibase migrations with properties file"
        cd $LIQUIBASE_DIR && exec java -cp "$CP" liquibase.integration.commandline.Main update "$@"
    else
        echo "Env variables not set, migrations will most likely fail"
    fi

else
    echo "Starting the application..."
   
    if [ $# -eq 0 ]; then
        # Run with defaults if no arguments are passed
        java -jar app.jar --server.port=8080
    else
        # Run the Spring Boot application, passing all arguments
        exec java -jar "$APP_JAR" "$@"
    fi
fi

```


## Examples:
### Managing "Schema-ish" Evolution
Even without a rigid schema, your documents evolve. If you move from a flat structure to a nested one, you need to ensure every document in the collection is updated before the new application code hits production.

  The Scenario: You are moving a phone_number string field into a contact_info object.

  The Liquibase Benefit: You can write a changeSet using a mongo shell script to migrate all existing documents. This ensures your "v2" code doesn't crash when it encounters "v1" data.

### Automating Index Management
Indexes are critical for MongoDB performance. Manually creating them in every environment (Dev, QA, Prod) is prone to human error, leading to "COLLSCAN" (collection scan) performance issues in production that didn't exist in Dev.

  The Scenario: You need a compound index on { "orgId": 1, "createdAt": -1 } to support a new dashboard.

  The Liquibase Benefit: You define the index in a changelog.xml or changelog.yaml. When the pipeline runs, Liquibase checks if the index exists; if not, it creates it. This keeps your indexing strategy identical across all clusters.

### Seed Data and Configuration
Most applications require "bootstrap" data—roles, permissions, country codes, or system settings to function correctly upon first deployment.

  The Scenario: Setting up initial admin roles and default system configurations in a settings collection.

  The Liquibase Benefit: You can use the insertMany command within a changeSet. This makes "spinning up" a fresh environment (like a feature-branch preview) fully automated and consistent.

### Validating Collection Structures
MongoDB 3.2+ supports JSON Schema Validation. This allows you to enforce rules (e.g., "the email field must be a string and follow this regex").

  The Scenario: Your business requires strict data integrity for a transactions collection.

  The Liquibase Benefit: You can use Liquibase to apply or update collMod commands that define these validation rules. As your business logic changes, your validation rules evolve alongside your code via the changelog.
