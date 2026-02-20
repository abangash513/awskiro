# GraphQL Authentication & Authorization

## Overview

This document covers how to set up authentication and authorization for GraphQL subgraphs.

**Reference**: [Policy Management](https://developer.aa.com/docs/default/component/graphql-software-templates/usage/policy-management/)

---

## Authentication

To authenticate requests to your GraphQL subgraph, you need to create a consumer application in Apigee.

### Steps to Set Up Authentication

1. **Create a Consumer Application in Apigee**
   - Navigate to the Apigee portal
   - Create a new consumer application

2. **Configure Identity Authorities**
   
   Select the appropriate identity authority for your use case:
   | Identity Authority | Use Case |
   |--------------------|----------|
   | Ping | Enterprise SSO authentication |
   | Apigee | API-to-API authentication |
   | AAD (Azure Active Directory) | Azure-based authentication |

3. **Get API Key and Token**
   - Once the consumer application is created, obtain your API key
   - Use the API key to request an API token for authenticating GraphQL requests

### Using the API Token

Include the token in your GraphQL request headers:

```http
Authorization: Bearer <your-api-token>
```

### Required Headers for Subgraph Access

> ⚠️ **Important**: The `apollographql-client-name` header is required when accessing the subgraph.

This header should contain the Archer name for the client application.

```http
Authorization: Bearer <your-api-token>
apollographql-client-name: OpsPlatNext
```

| Header | Description | Example |
|--------|-------------|--------|
| `Authorization` | Bearer token from Apigee | `Bearer eyJhbGc...` |
| `apollographql-client-name` | Archer name of the client application | `OpsPlatNext` |

---

## Authorization

Authorization is handled using the `@policy` directive in your GraphQL schema. Policies are created and managed in Runway.

### Creating Policies in Runway

To create policies for the `@policy` directive:

👉 **Policy Management Portal**: [https://developer.aa.com/graphql/policy-management](https://developer.aa.com/graphql/policy-management)

#### Steps to Create a Policy

1. **Navigate to the Policy Management Portal**
   - Go to [developer.aa.com/graphql/policy-management](https://developer.aa.com/graphql/policy-management)

2. **Create Your Policy**
   - Define the policy name and access rules
   - Submit the policy creation request

3. **Approve the Pull Request**
   - Creating a policy generates a PR in the [graphql-policies repository](https://github.com/AAInternal/graphql-policies)
   - The PR must be approved by the **Data Movement team**

### Requesting Access to an Existing Policy

If you need access to an existing policy, you can request it through the portal:

1. **Navigate to the Policy Management Portal**
   - Go to [developer.aa.com/graphql/policy-management](https://developer.aa.com/graphql/policy-management)

2. **Submit a Policy Request** with the following information:
   | Field | Description |
   |-------|-------------|
   | Client ID | Your application's client identifier |
   | Email | Distribution List (DL) email address |
   | Short Name | Application short name |
   | GitHub Team | Your GitHub team for approval |

   > ⚠️ **Note**: The email must be a Distribution List (DL) email, not a personal email.

3. **Approval Process**
   - This creates a PR that the **policy owner team** must approve
   - Once approved, your application will have access to the policy

### Using the @policy Directive

Apply the `@policy` directive to your GraphQL queries and mutations to enforce authorization:

```graphql
type Query {
    """
    Get the latest ADL snapshot.

    Returns the most recent ADL containing all arrivals and departures.
    - If station is provided, returns the latest ADL for that specific station.
    - If station is null/not provided, returns the latest ADL across all stations.

    Use this for real-time operational views of a station or system-wide overview.
    """
    latestAdl(
        "Station code - Airport, FEA, or FCA identifier (e.g., BWI, DFW, ZNY_FEA). If null, returns latest across all stations."
        station: String
        "Include stale ADLs - If true, returns most recent ADL regardless of staleness. Default: false"
        includeStale: Boolean = false
    ): Adl @policy(policies: [["nxop-adl-subgraph-policy"]])
}
```

### @policy Directive Syntax

```graphql
@policy(policies: [["policy-name"]])
```

- **policies**: An array of policy arrays
  - Outer array: OR conditions (any policy group must pass)
  - Inner array: AND conditions (all policies in the group must pass)

### Examples

**Single Policy:**
```graphql
@policy(policies: [["my-policy"]])
```

**Multiple Policies (AND - all must pass):**
```graphql
@policy(policies: [["policy-a", "policy-b"]])
```

**Multiple Policies (OR - any must pass):**
```graphql
@policy(policies: [["policy-a"], ["policy-b"]])
```

---

## Summary

| Aspect | Tool | Action |
|--------|------|--------|
| Authentication | Apigee | Create consumer app, get API key/token |
| Authorization | Runway | Create policies using GraphQL plugin |
| Schema | GraphQL | Apply `@policy` directive |

---

## Related Documentation

- [Schema Design](schema-design.md) - Guidelines for designing GraphQL schemas
- [Creating a GraphQL Application](creating-graphql-application.md) - Setting up a Spring Boot GraphQL app
- [Reusable Workflows](reusable-workflows.md) - Schema publish and check workflows
