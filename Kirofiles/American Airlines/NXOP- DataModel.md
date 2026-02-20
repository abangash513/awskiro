# NXOP- DataModel


NXOP: Data Model
NXOP Common Data Model - Domain-Driven Design

• The NXOP CDM is designed as an operational, real-time, document-oriented model aligned with the NXOP architecture. Data-Driven Design supports real-
  time operations, historical snapshots, API-based reads and event-driven changes

  Why Domain-Driven Design:
• Operational Hot Tier: Flight data must support real-time reads/writes, low latency, and multi-region active-active replication
• System of Record: GraphQL consumers expect one unified flight object without joins
• Event-Heavy Workload: OPSHUB generates millions of events → embedding events ensures fast retrieval
• Flexible Evolution: DocumentDB allows polymorphic sub-structures, perfect for OPSHUB’s variable event schemas
• DDD-based Structure: Domain-Driven Design ensures each domain and sub-domain is cleanly separated and maintainable

  Terminology:
• Domain: Business area that groups similar concepts together. It is the broad problem space the system exists to model and solve
• Subdomain: Smaller, focused part of the domain that handles the specific business capability
• Entity: Unique identifiable object in the domain whose identity stays constant even if its data changes
• Attributes: Properties or characteristics of the Entities
• Links (Relationships): Connection between entities




                                                                                                                                                     2
NXOP Domains & Subdomains - Domain (Top Level)

• Flight Domain: Core operational truth of a flight: identity, times, legs, communication feeds and status. Represents the lifecycle of a flight from schedule
  → updates → completion
• Aircraft Domain: Everything related to aircraft identity and core characteristics.Static and semi-static information about aircraft identity, type, configuration
• Station Domain: Everything related to airports stations and gates.
• Maintenance Domain: Everything related to maintenance schedules or maintenance logs
• ADL Domain: Provides the latest operational flight metadata and snapshots from FOS, serving as a centralized, near-real-time reference of flight state,
  schedule, and key operational attributes




                                                                                                                                                                  3
Flight Domain
• The Flight Domain represents the end-to-end lifecycle of a flight across multiple systems
• It is divided into 7 sub-domains, each mapped to its own entity
• Each sub-domain is stored as a separate entity, mapped with 1 -> 1 relationship, and linked by the flightKey


Entities:

 1.   FlightIdentity

 2.   FlightTimes

 3.   FlightLeg

 4.   FlightEvent

 5.   FlightMetrics

 6.   FlightPosition

 7.   FlightLoadPlanning




                                                                                                                 4
     Entity: FlightIdentity (Parent)

     • Defines the unique identity of a flight on a given day.
     • Acts as the master reference for all other sub-domains.


     Key Characteristics

       •   Represents one ight (regardless of operational changes).

       •        ightKey is a single composite ID (carrier + ight number + ight date + departure station + dupDepCode).

       •   FlightKey is used as connection for all other Flight Domain entities.

     Core Fields
                                                                           Relationships
       •        ightKey (PK)
                                                                             •     1 → 1 with FlightTimes
       •   carrierCode
                                                                             •     1 → 1 with FlightLeg
       •        ightNumber
                                                                             •     1 → 1 with FlightEvent
       •        ightDate
                                                                             •     1 → 1 with FlightMetrics
       •   departureStation

       •   arrivalStation                                                    •     1 → 1 with FlightLoadPlanning

       •   dupDepCode




                                                                                                                         5
fl
fl
fl
fl
           fl
                                          fl
                                                          fl
Entity: FlightTimes
Captures time-related data for a ight across the entire lifecycle:

  •    Scheduled

  •    Estimated

  •    Actual

  •    Latest



Core Objects:

• Scheduled

• Estimated

• Actual

• Latest

• Metadata




                                                                     6
                         fl
Entity: FlightLeg
Represents the operational leg of a ight including:

  •    Routing

  •    Gate/terminal

  •    Previous and next leg information

  •    Equipment

  •    Status



Core Objects:

  •    LegInfo

  •    LegEquipment

  •    LegLinkage

  •    LegStatus

  •    Metadata




                                                      7
                            fl
     Entities: FlightEvent & EventHistory
     Entity: FlightEvent                                                                            Entity: EventHistory (Phase 2)
     Stores current and last known event state of the ight. It will have computed values as well.   Stores all historical events for a ight.
     Core Objects:                                                                                  Core Objects:
       •    FUFI
                                                                                                      •    event
       •    currentEventType
                                                                                                      •    eventData (JSON)
       •    currentEventTime
                                                                                                      •      tHubTimeStamp
       •    currentEventSequence
                                                                                                      •    sourceTimestamp
       •    lastEventType, lastEventTime
                                                                                                      •    dbUpdatedTime
       •    metadata_streamType, metadata_updateTimestamp
                                                                                                      •    trackingId

                                                                                                      •    snapshotId

     Relationships:                                                                                   •    rawOpshubEvent

     • FlightIdentity 1 → 1 FlightEvent

     • FlightEvent 1 → Many EventHistory




                                                                                                                                               8
fl
                               fl
                                               fl
Entity: FlightMetrics

Stores KPI-level performance and operational metrics extracted from Flight and OPSHUB.

Core Fields

 •    FuelMetrics

 •    PassengerMetrics

 •    PayloadMetrics

 •    WeightMetrics

 •    PerformanceMetrics




                                                                                         9
Entity: FlightLoadPlanning

Represents load plan for passengers, freight, bags, compartments, and cabin capacity.

Core Objects:

 •    LoadPlanPaxCounts

 •    LoadPlanWeights

 •    CabinCapacity




                                                                                        10
Entity: FlightPosition
Stores all aircraft movement and telemetry events reported via ACARS / ADS-B / ATC feeds.

Each record represents a single positional snapshot

Core Objects:

  •        geographic position

  •        speed & altitude

  •        ACARS message details

  •        aircraft identi ers

  •        OPSHUB metadata




                                                                                            11
      fi
 Station Domain
 The Station Domain represents airports and airline stations used across all ight operations. It provides a single, authoritative source of truth for station
 identity, geography, operational capabilities, and authorization rules.

 Primary data source is OPSHUB - Station / AirportInfo Collections


Why Station Domain Exists Separately:

• It provides a single, authoritative source of truth for station identity, geography, operational capabilities, and authorization
  rules
• Data is relatively static, changes infrequently, and is heavily reused by multiple domains


Entities:
• StationIdentity
• StationGeo
• StationAuthorization
• StationMetadata




                                                                                                                                                                12
                                                                         fl
Entity: StationIdentity (Parent)

Acts as the primary anchor for the Station Domain. It represents each unique station from the airline’s perspective, combining ICAO
airport and airline IATA station code.


Core Fields:

• icaoAirportID

• iataAirlineCode

• airportName

• stationName

• ataAirportID

• icaoAreaCode

• intlStation

• aaStation

• cat3LandingsAllowed

• coTerminalAllowed

• stationMaintClass

• actionCode

• timeStamp


                                                                                                                                      13
Entity: StationGeo

Stores geographical and physical characteristics of the station, used for operations, routing logic, and performance calculations.

Core Fields:

• latitude

• longitude

• elevation

• magneticVariation

• longestRunwayLength

• recommendedNAVAID

• recommendedNAVAIDICAOAreaCode




                                                                                                                                     14
Entity: StationAuthorization

Stores landing authorization con gurations for the station. Each authorization group is kept as an object with an internal array of items, preserving the
OPSHUB structure without exploding into many rows.


Core Objects:

• scheduledLandingsAuthorized[]

• charteredLandingsAuthorized[]

• driftdownLandingsAuthorized[]

• alternateLandingsAuthorized[]




                                                                                                                                                            15
                            fi
 Aircraft Domain
 Represents the authoritative master record of every aircraft in the airline’s eet.

 This domain centralizes con guration, performance limits, MEL items, operational status, and lifecycle attributes that are independent of any single ight.

 Primary data source is OPSHUB - Aircraft Collections

Why Station Domain Exists Separately:

• Aircraft lifecycle is independent of Flight lifecycle.
• Aircraft Information is reused across multiple domains




Entities:
• AircraftIdentity
• AircraftConfiguration
• AircraftLocation
• AircraftPerformance
• AircraftMEL




                                                                                                                                                              16
                          fi
                                                                         fl
                                                                                                                                               fl
Entity: AircraftIdentity (Parent)

Core aircraft identi ers used across ops systems. It is the aggregate root within the domain

Core Fields:

• carrierCode
• noseNumber
• registration
• numericCode
• mnemonicFleetCode
• mnemonicTypeCode
• marketingFleetCode
• ATCType
• FAANavCode
• alternateFAANAVCode
• heavyInd
• LUSInd
• specialInd


                                                                                               17
            fi
     Entity: AircraftConfiguration

     Represents the static structural con guration of the aircraft: cabin layout, type, SELCAL, and operator-de ned attributes

     Core Fields:

     • con guration.code

     • con guration.ATCType

     • con guration.FAANavCode

     • con guration.alternateFAANAVCode

     • con guration.marketingFleetCode

     • con guration.mnemonicFleetCode

     • con guration.mnemonicTypeCode

     • con guration.numericCode

     • con guration.heavyInd

     • con guration.LUSInd

     • con guration.specialInd

     • con guration.SELCAL

     • cabinCapacity

                                                                                                                                 18
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
                                    fi
                                                                                                        fi
     Entity: AircraftLocation

     Captures the aircraft’s current operational state, including last ight, next ight, overnight planning, and out-of-service status.

     Core Objects:

     Location:

        •    aircraftStatus

        •    controlledRouteInd

        •    outOfServiceCode

        •    openMELitems

        •    openSELitems

     LastCompletedFlight:

        •        tNum

        •    originDate

        •    dupArrCode

        •    arrivalTime

     NextFlight:

        •        tNum

        •    originDate

        •    dupDepCode

     PlannedOverNight:

        •    arrFltNum

        •    arrivalTime

        •    groundTime

        •    station

        •    returnToServiceTime




                                                                                                                                         19
fl
fl
                                                          fl
                                                                     fl
Entity: AircraftPerformance

Stores aircraft weight limits, operational performance values, and miscellaneous operational con guration indicators.

Core Objects:

weight (static):

   •    emptyOperatingWeight

   •    maximumFuelCapacity

   •    maximumLandingWeight

   •    maximumPayload

   •    maximumRampWeight

   •    maximumStructuralLandingWeight

   •    maximumStructuralRampWeight

   •    maximumStructuralTakeOffWeight

   •    minimumPayload

   •    zeroFuelWeight

weightMisc (Dynamic):

   •    capacityLifeRaftsCarried

   •    fuelFlowCorrectionFactor

   •    maximumAltitudeCorrectionFactor

   •    numberOfLifeRaftsCarried

   •    operationalEquipmentIndicators1

   •    operationalEquipmentIndicators2

   •    taxiFuelBurnRate

                                                                                                                        20
                                                                                       fi
     Entity: AircraftMEL

     Tracks active Minimum Equipment List (MEL) items, including issue, effectivity, subsystem, and closure details for maintenance operations

     Core Field:

     Minimum Equipment List (MEL):

     • ATASystemID

     • AMRNumber

     • subSystem

     • systemCode

     • description

     • issue.dateTime

     • issue.station

     • issue. ightNumber

     • itemPosition

     • manualReference

     • maxDays

     • MELNumber

     • positionCode

     • effectivity

     • close.dateTime

     • close.station

     • dispatcherInitials



                                                                                                                                                 21
fl
Maintenance Domain
The Maintenance Domain represents all aircraft maintenance operations reported through OPSHUB, including deferred defects, out-of-service status, airframe metrics, and
the complete maintenance event lifecycle.


Key Characteristics:
 • Event-driven data (trackingID per event)

 • Complex nested structures (DMI, OTS, LandingData)

 • Historical event chains (100+ entries)

 • Aircraft-centric and timestamp-heavy

 • High variability and update frequency



Entities:
• MaintenanceRecord
• MaintenanceDMI
• MaintenanceEquipment
• MaintenanceLandingData
• MaintenanceOTS
• MaintenanceEventHistory



                                                                                                                                                                          22
Entity: MaintenanceRecord (Parent)

Top-level snapshot of a maintenance event from OPSHUB. Every maintenance event and child entity is tied to this root.

Core Fields:

• trackingID

• airlineCode.iata

• airlineCode.icao

• tailNumber

• registration

• event

• schemaVersion

• fosPartition




                                                                                                                        23
Entity: MaintenanceDMI

List of deferred defects associated with the aircraft at the time of this maintenance event.

Core Fields:

• dmiId.ataCode

• dmiId.controlNumber

• dmiId.dmiClass

• dmiId.eqType

• dmiId.fmrId

• dmiId.lUScode

• dmiData.position

• dmiData.dmiText

• dmiData.multiplier

• dmiData.effectiveTime

                                                                                               24
Entity: MaintenanceEquipment

Records aircraft equipment con guration as captured in the maintenance event. Equipment values help determine performance and restrictions but are not
static like Aircraft domain.

Core Fields:

• equip. eetType

• equip.typeEq

• equip.numericEqType

• equip.eventSourceTimeStamp

• equip.updateTimeStamp




                                                                                                                                                         25
fl
                        fi
Entity: MaintenanceLandingData

Captures the aircraft’s lifetime operational metrics and ight relationships. Critical for heavy maintenance planning and ight-worthiness checks.

Core Fields:

• ttlTime (Total lifetime airframe time)

• cycles

• lastFlt. tNum, lastFlt.date, lastFlt.station

• nextFlt. tNum, nextFlt.date, nextFlt.station

• landingData.eventSourceTimeStamp

• landingData.updateTimeStamp




                                                                                                                                                   26
   fl
        fl
                                                 fl
                                                                                                                fl
ADL Domain
ADL Domain provides authoritative, near-real-time ight metadata and snapshots sourced from FOS, representing the operational state of the ight at the
time of the ADL feed.

It complements ASM/OPSHUB by delivering a uni ed, consistent snapshot of ight-level information used across multiple enterprise systems.

Key Characteristics:
• Its data is attened, canonical, and FOS-derived, making it a trusted operational reference for downstream systems.
• ADL records include unique elds such as snapshot timestamps, FOS indicators, and ADL-speci c metadata that do not belong in the core Flight domain.
• Preserving ADL as its own domain ensures clear lineage, easier ingestion logic, and better traceability of FOS snapshots.



Entities:
• adlHeader
• adlFlights




                                                                                                                                                        27
        fl
                         fi
                                             fi
                                                  fl
                                                                         fl
                                                                                             fi
                                                                                                                                     fl
     Entity: adlHeader

     Represents the top-level snapshot metadata for the ight extracted from ADL. Includes snapshot timestamp, ADL record ID, airline
     identi ers, and key operational ags.

     Used as the anchor for all other ADL sub-objects.




     Core Fields:

     • activeGdp

     • adlID

     • employeeId

     • runId

     • sessionId




                                                                                                                                       28
fi
                              fl
                                                  fl
     Entity: adlFlights

     Contains arrival and departure related metadata from the ADL feed.

     Re ects FOS’ view of arrival operations and state of departure authorization for that ight snapshot.




     Core Fields:

     • FlightKey

     • departureFlights

     • arrivalFlights

     • category

     • weightClass

     • delayCancelFlightSlotAvailability




                                                                                                            29
fl
                                                                                   fl
References

Sharepoint access - https://spteam.aa.com/sites/FOSModernization-NXOP/Shared%20Documents/Forms/AllItems.aspx?
id=%2Fsites%2FFOSModernization%2DNXOP%2FShared%20Documents%2FNXOP%2FNXOP%20Architectures%2FData%20Model&
viewid=b513ffa0%2D3d1a%2D40c4%2Dbb38%2D48503dd1c984



Schema - Common Data Model - Schema.xlsx




                                                                                                       30

