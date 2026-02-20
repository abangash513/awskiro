# Next Generation Operations Platform (NXOP) Charter

## Why a charter?

This charter establishes the foundational framework for the Next Generation Operations Platform (NXOP), serving as the authoritative guide for engineering teams, architects, and stakeholders in building and operating a modern, scalable platform for airline operations. This helps to answer, when is something built into NXOP (e.g., reusable business or technical capability), on top of NXOP (e.g., leveraging a reusable capability), or outside of NXOP (i.e., not within the first two categories).

See [Ownership and Governance](./ownership-and-governance.md) for details.

## Version History

| Version | Date | Description | Approvers |
|---------|------|-------------|-----------|
| 0.1 | 2025-09-10 | Initial draft | - |

## Purpose and Vision

To deliver a resilient, intelligent, and real-time digital platform that enables airline operations teams to
proactively manage, optimize, and recover flight, crew, aircraft, and ground operations—ultimately improving efficiency,
safety, and customer experience; this is the state of the Airline for decision making workloads within operations​

## Core Principles

- **Platform Design**: Support real-time capabilities, a composable architecture, digital twin grounding, and human operator decision-making​
- **Resiliency**: Ensure resilience by requiring all AA developed applications and vendor solutions to meet AA standards​
- **System Tiering**: Right-size systems for speed of delivery and cost based on criticality (i.e., best effort, essential, critical)​
- **Open Platform**: The platform is part of the overall Enterprise Data Strategy and is open for other systems to utilize data and key services​
- **Safety & Compliance**: Remain compliance with regulations set forth by FAA and IATA​
- **Evolvability**: Maintain ability to adapt the platform charter and architecture based on evolving demands and requirements​
- **Unified Data Fabric**: Govern and secure a single source of truth for operational real-time and historical data​
- **Security by Design**: Implement zero-trust architecture and data protection
- **Cost Optimization**: Balance performance requirements with operational efficiency
- **Developer Experience**: Provide intuitive, self-service capabilities for development teams
- **Observability**: Ensure comprehensive monitoring, logging, and alerting across all systems

## Workload Classification

The platform supports three distinct workload types with differentiated non-functional requirements:

- **Vital**: Mission-critical systems requiring maximum availability and performance
- **Critical**: Important business operations with standard SLA requirements  
- **Discretionary**: Non-essential workloads optimized for cost

## Charter Structure

This charter is organized into the following sections:

- **[Platform capabilities](platform-capabilities.md)**: Core capabilities that the platform will provide, which are solving for customer needs, integrated applications, and workloads
- **[Capability sourcing](capability-sourcing.md)**: Approach to determining which platform capabilities and applications should be developed by AA vs. bought from a third-party vendor
- **[Integration strategy](integration-strategy.md)**: Approach to compiling AA and external systems across various points of integration to ensure an efficient platform
- **[Architecture](architecture.md)**: The current and future state of the architecture of NXOP
- **[Ownership and governance](ownership-and-governance.md)**: Product management model used to inform future development and maintenance of the Next Gen Ops Platform including building on top of or within the platform; includes exception management for deviation from principles, patterns, and services
- **[KPIs and success metrics](kpis-and-success-metrics.md)**: Metrics that the Next Gen Ops Platform must support to enable efficient and safe airline operations (e.g., OTP, real-time event lag, etc.)
- **[Strategic alignment](strategic-alignment.md)**: Synchronization with broader enterprise initiatives (e.g., automation targets, environmental goals, etc.)
- **[Workload consolidation strategy](workload-consolidation-strategy.md)**: Workload latencies and archetypes should inform where cloud provider workloads are migrated to and in which sequence




---

*This charter serves as the foundation for all platform decisions and will be maintained by the Platform Architecture Board.*