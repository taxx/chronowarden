Request:
https://journeyplanner.integration.sl.se/v2/trips?type_origin=any&name_origin=9091001001009638&type_destination=any&name_destination=9091001001009660&date=2026-09-01&time=18:41&calc_number_of_trips=3 

Response:
```json
{
  "systemMessages": [
    
  ],
  "journeys": [
    {
      "tripDuration": 2220,
      "tripRtDuration": 2100,
      "rating": 0,
      "isAdditional": false,
      "interchanges": 0,
      "legs": [
        {
          "infos": [
            
          ],
          "duration": 2100,
          "origin": {
            "isGlobalId": true,
            "id": "9025001000007141",
            "name": "Mörby, Danderyd",
            "disassembledName": "1",
            "type": "platform",
            "coord": [
              59.392344,
              18.047459
            ],
            "niveau": 0,
            "parent": {
              "isGlobalId": true,
              "id": "9021001007141000",
              "name": "Mörby, Danderyd",
              "disassembledName": "Mörby",
              "type": "stop",
              "parent": {
                "id": "placeID:33001062:1",
                "name": "Danderyd",
                "type": "locality"
              },
              "properties": {
                "stopId": "18007141"
              },
              "coord": [
                59.392344,
                18.047451
              ],
              "niveau": 0
            },
            "productClasses": [
              4
            ],
            "departureTimeBaseTimetable": "2026-09-01T18:30:00Z",
            "departureTimePlanned": "2026-09-01T18:30:00Z",
            "departureTimeEstimated": "2026-09-01T18:31:18Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "1",
              "occupancy": "MANY_SEATS",
              "platform": "1",
              "stoppingPointPlanned": "1",
              "platformName": "1",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "destination": {
            "isGlobalId": true,
            "id": "9025001000007091",
            "name": "Österskär, Österåker",
            "disassembledName": "1",
            "type": "platform",
            "coord": [
              59.461375,
              18.310998
            ],
            "niveau": 0,
            "parent": {
              "isGlobalId": true,
              "id": "9021001006791000",
              "name": "Österskär, Österåker",
              "disassembledName": "Österskär",
              "type": "stop",
              "parent": {
                "id": "placeID:33001017:1",
                "name": "Österåker",
                "type": "locality"
              },
              "properties": {
                "stopId": "18006791"
              },
              "coord": [
                59.460754,
                18.311582
              ],
              "niveau": 0
            },
            "productClasses": [
              4
            ],
            "arrivalTimeBaseTimetable": "2026-09-01T19:07:00Z",
            "arrivalTimePlanned": "2026-09-01T19:07:00Z",
            "arrivalTimeEstimated": "2026-09-01T19:06:18Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "1",
              "platform": "1",
              "stoppingPointPlanned": "1",
              "platformName": "1",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "transportation": {
            "id": "tfs:03028: :R:y01",
            "name": "Spårvagn Roslagsbanan 28",
            "number": "Roslagsbanan 28",
            "product": {
              "id": 7,
              "class": 4,
              "name": "Spårvagn",
              "iconId": 4
            },
            "operator": {
              "id": "1",
              "name": "Storstockholms Lokaltrafik"
            },
            "destination": {
              "id": "18006791",
              "name": "Österskär via Åkersberga",
              "type": "stop"
            },
            "properties": {
              "tripCode": 453,
              "timetablePeriod": "Current",
              "lineDisplay": "LINE",
              "globalId": "9011001002800000",
              "RealtimeTripId": "9015001002806178",
              "shortTrain": true,
              "AVMSTripID": "9015001002806178"
            },
            "isSamtrafik": false,
            "disassembledName": "28"
          },
          "stopSequence": [
            {
              "isGlobalId": true,
              "id": "9025001000007141",
              "name": "Mörby, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.392344,
                18.047459
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007141000",
                "name": "Mörby, Danderyd",
                "disassembledName": "Mörby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007141"
                },
                "coord": [
                  59.392344,
                  18.047451
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:30:00Z",
              "departureTimeEstimated": "2026-09-01T18:31:18Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007154",
              "name": "Djursholms Ösby, Danderyd",
              "disassembledName": "4",
              "type": "platform",
              "coord": [
                59.399053,
                18.058949
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006651000",
                "name": "Djursholms Ösby, Danderyd",
                "disassembledName": "Djursholms Ösby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006651"
                },
                "coord": [
                  59.398705,
                  18.059236
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "4",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "4",
                "platformName": "4"
              },
              "departureTimePlanned": "2026-09-01T18:32:00Z",
              "departureTimeEstimated": "2026-09-01T18:33:06Z",
              "arrivalTimePlanned": "2026-09-01T18:32:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:32:18Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007161",
              "name": "Bråvallavägen, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.405587,
                18.060575
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006661000",
                "name": "Bråvallavägen, Danderyd",
                "disassembledName": "Bråvallavägen",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006661"
                },
                "coord": [
                  59.405587,
                  18.060602
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:33:00Z",
              "departureTimeEstimated": "2026-09-01T18:34:48Z",
              "arrivalTimePlanned": "2026-09-01T18:33:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:34:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007171",
              "name": "Djursholms Ekeby, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.412883,
                18.05753
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007171000",
                "name": "Djursholms Ekeby, Danderyd",
                "disassembledName": "Djursholms Ekeby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007171"
                },
                "coord": [
                  59.412892,
                  18.057664
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:35:00Z",
              "departureTimeEstimated": "2026-09-01T18:36:30Z",
              "arrivalTimePlanned": "2026-09-01T18:35:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:35:48Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007181",
              "name": "Enebyberg, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.425899,
                18.051241
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007181000",
                "name": "Enebyberg, Danderyd",
                "disassembledName": "Enebyberg",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007181"
                },
                "coord": [
                  59.42589,
                  18.051223
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:37:00Z",
              "departureTimeEstimated": "2026-09-01T18:39:00Z",
              "arrivalTimePlanned": "2026-09-01T18:37:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:38:06Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007192",
              "name": "Roslags Näsby, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.435196,
                18.057413
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007191000",
                "name": "Roslags Näsby, Täby",
                "disassembledName": "Roslags Näsby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007191"
                },
                "coord": [
                  59.435219,
                  18.057395
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T18:40:00Z",
              "departureTimeEstimated": "2026-09-01T18:41:06Z",
              "arrivalTimePlanned": "2026-09-01T18:40:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:40:06Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007001",
              "name": "Täby centrum, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.444377,
                18.074678
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007001000",
                "name": "Täby centrum, Täby",
                "disassembledName": "Täby centrum",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007001"
                },
                "coord": [
                  59.444336,
                  18.074634
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:41:00Z",
              "departureTimeEstimated": "2026-09-01T18:43:12Z",
              "arrivalTimePlanned": "2026-09-01T18:41:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:42:12Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007011",
              "name": "Galoppfältet, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.446952,
                18.085135
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007011000",
                "name": "Galoppfältet, Täby",
                "disassembledName": "Galoppfältet",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007011"
                },
                "coord": [
                  59.446902,
                  18.085162
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:43:00Z",
              "departureTimeEstimated": "2026-09-01T18:44:54Z",
              "arrivalTimePlanned": "2026-09-01T18:43:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:44:06Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007023",
              "name": "Viggbyholm, Täby",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.449235,
                18.104188
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007021000",
                "name": "Viggbyholm, Täby",
                "disassembledName": "Viggbyholm",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007021"
                },
                "coord": [
                  59.449254,
                  18.104215
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "3",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T18:45:00Z",
              "departureTimeEstimated": "2026-09-01T18:46:48Z",
              "arrivalTimePlanned": "2026-09-01T18:45:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:46:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007031",
              "name": "Hägernäs, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.450884,
                18.1252
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007031000",
                "name": "Hägernäs, Täby",
                "disassembledName": "Hägernäs",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007031"
                },
                "coord": [
                  59.450916,
                  18.125227
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:48:00Z",
              "departureTimeEstimated": "2026-09-01T18:49:00Z",
              "arrivalTimePlanned": "2026-09-01T18:48:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:48:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007035",
              "name": "Arninge, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.458919,
                18.141199
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007035000",
                "name": "Arninge, Täby",
                "disassembledName": "Arninge",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007035"
                },
                "coord": [
                  59.458864,
                  18.141351
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:50:00Z",
              "departureTimeEstimated": "2026-09-01T18:51:00Z",
              "arrivalTimePlanned": "2026-09-01T18:50:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:50:24Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007042",
              "name": "Rydbo, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.465323,
                18.185836
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006741000",
                "name": "Rydbo, Österåker",
                "disassembledName": "Rydbo",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006741"
                },
                "coord": [
                  59.465409,
                  18.185863
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T18:54:00Z",
              "departureTimeEstimated": "2026-09-01T18:54:36Z",
              "arrivalTimePlanned": "2026-09-01T18:54:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:53:12Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007051",
              "name": "Täljö, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.473199,
                18.235441
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007051000",
                "name": "Täljö, Österåker",
                "disassembledName": "Täljö",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007051"
                },
                "coord": [
                  59.473227,
                  18.235396
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:57:00Z",
              "departureTimeEstimated": "2026-09-01T18:58:00Z",
              "arrivalTimePlanned": "2026-09-01T18:57:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:57:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007061",
              "name": "Åkers Runö, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.480618,
                18.270403
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006761000",
                "name": "Åkers Runö, Österåker",
                "disassembledName": "Åkers Runö",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006761"
                },
                "coord": [
                  59.480645,
                  18.270412
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:00:00Z",
              "departureTimeEstimated": "2026-09-01T19:00:42Z",
              "arrivalTimePlanned": "2026-09-01T19:00:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:59:36Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007071",
              "name": "Åkersberga, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.479016,
                18.299769
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007071000",
                "name": "Åkersberga, Österåker",
                "disassembledName": "Åkersberga",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007071"
                },
                "coord": [
                  59.479003,
                  18.299778
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:03:00Z",
              "departureTimeEstimated": "2026-09-01T19:03:18Z",
              "arrivalTimePlanned": "2026-09-01T19:03:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:01:42Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007081",
              "name": "Tunagård, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.468746,
                18.307432
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006781000",
                "name": "Tunagård, Österåker",
                "disassembledName": "Tunagård",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006781"
                },
                "coord": [
                  59.468755,
                  18.307306
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:04:00Z",
              "departureTimeEstimated": "2026-09-01T19:05:48Z",
              "arrivalTimePlanned": "2026-09-01T19:04:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:04:30Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007091",
              "name": "Österskär, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.461375,
                18.310998
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006791000",
                "name": "Österskär, Österåker",
                "disassembledName": "Österskär",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006791"
                },
                "coord": [
                  59.460754,
                  18.311582
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "arrivalTimePlanned": "2026-09-01T19:07:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:06:18Z"
            }
          ],
          "properties": {
            "tripId": "9015001002806178"
          },
          "coords": [
            [
              59.39234,
              18.04745
            ],
            [
              59.392442,
              18.047565
            ],
            [
              59.392495,
              18.04763
            ],
            [
              59.392731,
              18.047947
            ],
            [
              59.392817,
              18.048069
            ],
            [
              59.39304,
              18.048398
            ],
            [
              59.393088,
              18.04848
            ],
            [
              59.393278,
              18.048814
            ],
            [
              59.393522,
              18.049264
            ],
            [
              59.393846,
              18.049954
            ],
            [
              59.393887,
              18.050049
            ],
            [
              59.394154,
              18.050715
            ],
            [
              59.394208,
              18.05087
            ],
            [
              59.394497,
              18.051747
            ],
            [
              59.394544,
              18.051909
            ],
            [
              59.394755,
              18.052653
            ],
            [
              59.39499,
              18.053527
            ],
            [
              59.395274,
              18.054701
            ],
            [
              59.395519,
              18.055576
            ],
            [
              59.395541,
              18.055647
            ],
            [
              59.395573,
              18.055733
            ],
            [
              59.395719,
              18.056124
            ],
            [
              59.395752,
              18.056207
            ],
            [
              59.395795,
              18.056301
            ],
            [
              59.395948,
              18.056621
            ],
            [
              59.395993,
              18.056712
            ],
            [
              59.396024,
              18.056768
            ],
            [
              59.396178,
              18.057026
            ],
            [
              59.396212,
              18.057075
            ],
            [
              59.396266,
              18.057142
            ],
            [
              59.39661,
              18.05756
            ],
            [
              59.397,
              18.057973
            ],
            [
              59.397038,
              18.058008
            ],
            [
              59.397068,
              18.058032
            ],
            [
              59.397709,
              18.058496
            ],
            [
              59.3979,
              18.058538
            ],
            [
              59.397963,
              18.058555
            ],
            [
              59.398515,
              18.058774
            ],
            [
              59.398578,
              18.058795
            ],
            [
              59.39905,
              18.058897
            ],
            [
              59.39905,
              18.058951
            ],
            [
              59.399256,
              18.058991
            ],
            [
              59.400742,
              18.059221
            ],
            [
              59.401899,
              18.059356
            ],
            [
              59.403262,
              18.059482
            ],
            [
              59.403923,
              18.059698
            ],
            [
              59.404431,
              18.059914
            ],
            [
              59.405355,
              18.060486
            ],
            [
              59.405585,
              18.06057
            ],
            [
              59.406292,
              18.06083
            ],
            [
              59.406862,
              18.060778
            ],
            [
              59.408775,
              18.059807
            ],
            [
              59.409923,
              18.059177
            ],
            [
              59.412893,
              18.057672
            ],
            [
              59.413371,
              18.057429
            ],
            [
              59.414074,
              18.056992
            ],
            [
              59.414383,
              18.056679
            ],
            [
              59.414698,
              18.056195
            ],
            [
              59.415005,
              18.055596
            ],
            [
              59.415388,
              18.054673
            ],
            [
              59.415972,
              18.053422
            ],
            [
              59.416373,
              18.052807
            ],
            [
              59.416832,
              18.052241
            ],
            [
              59.41734,
              18.051728
            ],
            [
              59.419029,
              18.050202
            ],
            [
              59.419526,
              18.049941
            ],
            [
              59.42,
              18.049792
            ],
            [
              59.420687,
              18.049822
            ],
            [
              59.421287,
              18.049968
            ],
            [
              59.421996,
              18.050213
            ],
            [
              59.423688,
              18.051235
            ],
            [
              59.424447,
              18.051235
            ],
            [
              59.425219,
              18.051221
            ],
            [
              59.425894,
              18.051237
            ],
            [
              59.425975,
              18.051239
            ],
            [
              59.426573,
              18.051043
            ],
            [
              59.429686,
              18.051108
            ],
            [
              59.430157,
              18.051235
            ],
            [
              59.430588,
              18.051387
            ],
            [
              59.430924,
              18.051575
            ],
            [
              59.431227,
              18.051784
            ],
            [
              59.43149,
              18.052004
            ],
            [
              59.432089,
              18.05257
            ],
            [
              59.432696,
              18.053237
            ],
            [
              59.432853,
              18.05346
            ],
            [
              59.433005,
              18.053715
            ],
            [
              59.4345,
              18.056329
            ],
            [
              59.435069,
              18.057197
            ],
            [
              59.435198,
              18.057416
            ],
            [
              59.435272,
              18.057542
            ],
            [
              59.435627,
              18.058066
            ],
            [
              59.436154,
              18.058596
            ],
            [
              59.436817,
              18.059265
            ],
            [
              59.437021,
              18.059497
            ],
            [
              59.43739,
              18.05997
            ],
            [
              59.437752,
              18.060508
            ],
            [
              59.438172,
              18.061259
            ],
            [
              59.440956,
              18.067235
            ],
            [
              59.441976,
              18.069362
            ],
            [
              59.442471,
              18.070576
            ],
            [
              59.443483,
              18.072734
            ],
            [
              59.444262,
              18.0744
            ],
            [
              59.44438,
              18.074691
            ],
            [
              59.44438,
              18.07469
            ],
            [
              59.444519,
              18.075031
            ],
            [
              59.444556,
              18.075132
            ],
            [
              59.444741,
              18.075672
            ],
            [
              59.444774,
              18.07578
            ],
            [
              59.445716,
              18.079265
            ],
            [
              59.446307,
              18.081624
            ],
            [
              59.446383,
              18.081935
            ],
            [
              59.446472,
              18.082338
            ],
            [
              59.446557,
              18.082709
            ],
            [
              59.446706,
              18.083406
            ],
            [
              59.446731,
              18.083529
            ],
            [
              59.446746,
              18.083608
            ],
            [
              59.446785,
              18.083847
            ],
            [
              59.446831,
              18.084192
            ],
            [
              59.44689,
              18.084704
            ],
            [
              59.446934,
              18.085136
            ],
            [
              59.446944,
              18.085243
            ],
            [
              59.446973,
              18.085602
            ],
            [
              59.447094,
              18.087033
            ],
            [
              59.447291,
              18.089118
            ],
            [
              59.447376,
              18.089998
            ],
            [
              59.447486,
              18.091157
            ],
            [
              59.447739,
              18.093984
            ],
            [
              59.447786,
              18.09454
            ],
            [
              59.447844,
              18.095138
            ],
            [
              59.447986,
              18.0968
            ],
            [
              59.448144,
              18.09871
            ],
            [
              59.448164,
              18.098903
            ],
            [
              59.448204,
              18.099351
            ],
            [
              59.448244,
              18.09978
            ],
            [
              59.448277,
              18.100105
            ],
            [
              59.448287,
              18.100206
            ],
            [
              59.448348,
              18.100711
            ],
            [
              59.448375,
              18.100908
            ],
            [
              59.448435,
              18.101299
            ],
            [
              59.448561,
              18.10198
            ],
            [
              59.448588,
              18.102113
            ],
            [
              59.448628,
              18.102281
            ],
            [
              59.448695,
              18.102539
            ],
            [
              59.448731,
              18.102666
            ],
            [
              59.448793,
              18.102878
            ],
            [
              59.448821,
              18.102965
            ],
            [
              59.448839,
              18.103017
            ],
            [
              59.448946,
              18.103308
            ],
            [
              59.449062,
              18.103631
            ],
            [
              59.449268,
              18.104143
            ],
            [
              59.449476,
              18.104656
            ],
            [
              59.449722,
              18.105214
            ],
            [
              59.449776,
              18.105317
            ],
            [
              59.45015,
              18.105984
            ],
            [
              59.450288,
              18.106222
            ],
            [
              59.450337,
              18.106303
            ],
            [
              59.450658,
              18.106753
            ],
            [
              59.451112,
              18.107436
            ],
            [
              59.451406,
              18.107944
            ],
            [
              59.451791,
              18.108556
            ],
            [
              59.452221,
              18.109294
            ],
            [
              59.452323,
              18.109486
            ],
            [
              59.452401,
              18.109641
            ],
            [
              59.452428,
              18.1097
            ],
            [
              59.452461,
              18.109779
            ],
            [
              59.452537,
              18.109975
            ],
            [
              59.45258,
              18.110092
            ],
            [
              59.452701,
              18.110477
            ],
            [
              59.452786,
              18.110779
            ],
            [
              59.4528,
              18.110834
            ],
            [
              59.452815,
              18.110905
            ],
            [
              59.452877,
              18.111233
            ],
            [
              59.452902,
              18.111394
            ],
            [
              59.452928,
              18.111571
            ],
            [
              59.452952,
              18.111745
            ],
            [
              59.452962,
              18.111846
            ],
            [
              59.452981,
              18.112135
            ],
            [
              59.452994,
              18.112432
            ],
            [
              59.452998,
              18.112619
            ],
            [
              59.452996,
              18.11286
            ],
            [
              59.452988,
              18.113108
            ],
            [
              59.45298,
              18.113232
            ],
            [
              59.452939,
              18.113677
            ],
            [
              59.452922,
              18.113814
            ],
            [
              59.452875,
              18.11409
            ],
            [
              59.452805,
              18.114442
            ],
            [
              59.452709,
              18.114872
            ],
            [
              59.45257,
              18.11548
            ],
            [
              59.452376,
              18.116375
            ],
            [
              59.452352,
              18.11649
            ],
            [
              59.452252,
              18.117013
            ],
            [
              59.452133,
              18.117728
            ],
            [
              59.452111,
              18.117868
            ],
            [
              59.452043,
              18.118354
            ],
            [
              59.451945,
              18.119091
            ],
            [
              59.451773,
              18.12029
            ],
            [
              59.451685,
              18.120881
            ],
            [
              59.45162,
              18.121352
            ],
            [
              59.451523,
              18.121962
            ],
            [
              59.451364,
              18.122982
            ],
            [
              59.451304,
              18.123337
            ],
            [
              59.45126,
              18.123573
            ],
            [
              59.451221,
              18.123768
            ],
            [
              59.451102,
              18.124337
            ],
            [
              59.451069,
              18.124488
            ],
            [
              59.45099,
              18.124833
            ],
            [
              59.450896,
              18.125213
            ],
            [
              59.45067,
              18.126074
            ],
            [
              59.450586,
              18.126368
            ],
            [
              59.450447,
              18.126839
            ],
            [
              59.450246,
              18.127567
            ],
            [
              59.450095,
              18.128088
            ],
            [
              59.450065,
              18.128197
            ],
            [
              59.450036,
              18.128323
            ],
            [
              59.450009,
              18.128451
            ],
            [
              59.449908,
              18.128976
            ],
            [
              59.449852,
              18.129292
            ],
            [
              59.449835,
              18.129412
            ],
            [
              59.449818,
              18.129554
            ],
            [
              59.449801,
              18.129733
            ],
            [
              59.449793,
              18.129852
            ],
            [
              59.44979,
              18.13
            ],
            [
              59.44979,
              18.130147
            ],
            [
              59.449796,
              18.130407
            ],
            [
              59.449804,
              18.130559
            ],
            [
              59.449814,
              18.130698
            ],
            [
              59.44986,
              18.131237
            ],
            [
              59.449878,
              18.131399
            ],
            [
              59.449886,
              18.131457
            ],
            [
              59.449902,
              18.131547
            ],
            [
              59.450026,
              18.132161
            ],
            [
              59.450072,
              18.132338
            ],
            [
              59.450111,
              18.132477
            ],
            [
              59.450179,
              18.132683
            ],
            [
              59.450221,
              18.132801
            ],
            [
              59.450259,
              18.1329
            ],
            [
              59.450293,
              18.132979
            ],
            [
              59.450465,
              18.133348
            ],
            [
              59.450519,
              18.133448
            ],
            [
              59.450657,
              18.133679
            ],
            [
              59.450708,
              18.133759
            ],
            [
              59.450912,
              18.13402
            ],
            [
              59.45103,
              18.134152
            ],
            [
              59.451085,
              18.13421
            ],
            [
              59.452101,
              18.1351
            ],
            [
              59.453436,
              18.136211
            ],
            [
              59.45358,
              18.136324
            ],
            [
              59.454218,
              18.136877
            ],
            [
              59.454887,
              18.137444
            ],
            [
              59.455072,
              18.137619
            ],
            [
              59.455412,
              18.137915
            ],
            [
              59.457123,
              18.139547
            ],
            [
              59.45769,
              18.140161
            ],
            [
              59.458179,
              18.140801
            ],
            [
              59.4588,
              18.14157
            ],
            [
              59.458823,
              18.141612
            ],
            [
              59.459633,
              18.142703
            ],
            [
              59.460273,
              18.143721
            ],
            [
              59.461317,
              18.145282
            ],
            [
              59.461747,
              18.146031
            ],
            [
              59.462401,
              18.147983
            ],
            [
              59.463216,
              18.152164
            ],
            [
              59.463522,
              18.154022
            ],
            [
              59.464183,
              18.157238
            ],
            [
              59.465068,
              18.160475
            ],
            [
              59.465479,
              18.161938
            ],
            [
              59.465602,
              18.162231
            ],
            [
              59.46575,
              18.16256
            ],
            [
              59.465787,
              18.162635
            ],
            [
              59.465912,
              18.162862
            ],
            [
              59.466087,
              18.163165
            ],
            [
              59.466297,
              18.16351
            ],
            [
              59.466616,
              18.163957
            ],
            [
              59.466882,
              18.164335
            ],
            [
              59.466941,
              18.164423
            ],
            [
              59.467225,
              18.164919
            ],
            [
              59.467284,
              18.165041
            ],
            [
              59.467443,
              18.165385
            ],
            [
              59.467499,
              18.165511
            ],
            [
              59.467671,
              18.165922
            ],
            [
              59.467698,
              18.165993
            ],
            [
              59.467726,
              18.166081
            ],
            [
              59.467795,
              18.166319
            ],
            [
              59.467917,
              18.166758
            ],
            [
              59.468014,
              18.167127
            ],
            [
              59.468044,
              18.16726
            ],
            [
              59.468089,
              18.167472
            ],
            [
              59.468103,
              18.167549
            ],
            [
              59.468124,
              18.167684
            ],
            [
              59.468143,
              18.16782
            ],
            [
              59.468184,
              18.168147
            ],
            [
              59.468222,
              18.168493
            ],
            [
              59.468239,
              18.168675
            ],
            [
              59.468273,
              18.169097
            ],
            [
              59.468297,
              18.169499
            ],
            [
              59.468307,
              18.169739
            ],
            [
              59.468312,
              18.169878
            ],
            [
              59.468315,
              18.17004
            ],
            [
              59.468316,
              18.170162
            ],
            [
              59.468316,
              18.170286
            ],
            [
              59.468312,
              18.170451
            ],
            [
              59.468302,
              18.170597
            ],
            [
              59.46828,
              18.170866
            ],
            [
              59.468238,
              18.171333
            ],
            [
              59.468189,
              18.171768
            ],
            [
              59.468136,
              18.172225
            ],
            [
              59.468064,
              18.172725
            ],
            [
              59.468004,
              18.173105
            ],
            [
              59.467909,
              18.173676
            ],
            [
              59.467799,
              18.174265
            ],
            [
              59.467693,
              18.174786
            ],
            [
              59.467577,
              18.175321
            ],
            [
              59.467532,
              18.17551
            ],
            [
              59.467283,
              18.176457
            ],
            [
              59.467242,
              18.176604
            ],
            [
              59.466751,
              18.178202
            ],
            [
              59.466342,
              18.179555
            ],
            [
              59.466094,
              18.180451
            ],
            [
              59.466059,
              18.1806
            ],
            [
              59.465994,
              18.180901
            ],
            [
              59.465859,
              18.181564
            ],
            [
              59.465727,
              18.182285
            ],
            [
              59.465665,
              18.182672
            ],
            [
              59.465621,
              18.182971
            ],
            [
              59.4656,
              18.183131
            ],
            [
              59.465565,
              18.183427
            ],
            [
              59.46553,
              18.183762
            ],
            [
              59.465459,
              18.184572
            ],
            [
              59.465444,
              18.184806
            ],
            [
              59.46541,
              18.185302
            ],
            [
              59.46539,
              18.185709
            ],
            [
              59.465385,
              18.185855
            ],
            [
              59.465367,
              18.186534
            ],
            [
              59.465368,
              18.186744
            ],
            [
              59.465371,
              18.187033
            ],
            [
              59.465377,
              18.187339
            ],
            [
              59.465387,
              18.187677
            ],
            [
              59.465432,
              18.188531
            ],
            [
              59.465464,
              18.188955
            ],
            [
              59.465494,
              18.189278
            ],
            [
              59.465505,
              18.18938
            ],
            [
              59.465571,
              18.189949
            ],
            [
              59.465637,
              18.190418
            ],
            [
              59.465673,
              18.190645
            ],
            [
              59.465728,
              18.191029
            ],
            [
              59.465762,
              18.191228
            ],
            [
              59.4659,
              18.191974
            ],
            [
              59.465975,
              18.192339
            ],
            [
              59.466043,
              18.192635
            ],
            [
              59.466097,
              18.192858
            ],
            [
              59.466158,
              18.1931
            ],
            [
              59.466232,
              18.193379
            ],
            [
              59.466252,
              18.193453
            ],
            [
              59.46636,
              18.193819
            ],
            [
              59.466493,
              18.194283
            ],
            [
              59.466689,
              18.194939
            ],
            [
              59.46682,
              18.195362
            ],
            [
              59.466959,
              18.195827
            ],
            [
              59.467472,
              18.197512
            ],
            [
              59.467523,
              18.197675
            ],
            [
              59.467712,
              18.198264
            ],
            [
              59.467907,
              18.198911
            ],
            [
              59.467951,
              18.199079
            ],
            [
              59.468258,
              18.20029
            ],
            [
              59.4684,
              18.200933
            ],
            [
              59.468431,
              18.201082
            ],
            [
              59.468492,
              18.201394
            ],
            [
              59.468631,
              18.20214
            ],
            [
              59.468677,
              18.202426
            ],
            [
              59.468762,
              18.203016
            ],
            [
              59.468804,
              18.20332
            ],
            [
              59.468854,
              18.203717
            ],
            [
              59.468904,
              18.20414
            ],
            [
              59.468957,
              18.204536
            ],
            [
              59.469001,
              18.204843
            ],
            [
              59.469111,
              18.205804
            ],
            [
              59.469206,
              18.20656
            ],
            [
              59.469313,
              18.207471
            ],
            [
              59.469347,
              18.207775
            ],
            [
              59.469359,
              18.207897
            ],
            [
              59.469411,
              18.208472
            ],
            [
              59.46945,
              18.20893
            ],
            [
              59.469482,
              18.209373
            ],
            [
              59.469509,
              18.209914
            ],
            [
              59.469532,
              18.210615
            ],
            [
              59.469543,
              18.211945
            ],
            [
              59.469526,
              18.212486
            ],
            [
              59.469441,
              18.214147
            ],
            [
              59.469361,
              18.215391
            ],
            [
              59.469392,
              18.215397
            ],
            [
              59.469377,
              18.215568
            ],
            [
              59.469357,
              18.21577
            ],
            [
              59.469331,
              18.215987
            ],
            [
              59.469275,
              18.217747
            ],
            [
              59.469185,
              18.220115
            ],
            [
              59.469171,
              18.221082
            ],
            [
              59.469182,
              18.221807
            ],
            [
              59.469205,
              18.222654
            ],
            [
              59.469241,
              18.223234
            ],
            [
              59.469289,
              18.223839
            ],
            [
              59.469362,
              18.224395
            ],
            [
              59.469435,
              18.225024
            ],
            [
              59.469508,
              18.225411
            ],
            [
              59.469581,
              18.225968
            ],
            [
              59.469703,
              18.226645
            ],
            [
              59.469837,
              18.227178
            ],
            [
              59.470033,
              18.228074
            ],
            [
              59.470265,
              18.228776
            ],
            [
              59.470497,
              18.229648
            ],
            [
              59.470754,
              18.230278
            ],
            [
              59.471,
              18.230812
            ],
            [
              59.471118,
              18.23108
            ],
            [
              59.471183,
              18.231193
            ],
            [
              59.47126,
              18.231349
            ],
            [
              59.471247,
              18.231374
            ],
            [
              59.471299,
              18.231395
            ],
            [
              59.471404,
              18.231614
            ],
            [
              59.472425,
              18.233702
            ],
            [
              59.472531,
              18.233923
            ],
            [
              59.472753,
              18.234374
            ],
            [
              59.473232,
              18.235367
            ],
            [
              59.473369,
              18.23565
            ],
            [
              59.473577,
              18.23607
            ],
            [
              59.473977,
              18.236867
            ],
            [
              59.474082,
              18.237087
            ],
            [
              59.47445,
              18.237813
            ],
            [
              59.474571,
              18.238061
            ],
            [
              59.474668,
              18.238272
            ],
            [
              59.474791,
              18.238558
            ],
            [
              59.475026,
              18.239131
            ],
            [
              59.475062,
              18.239229
            ],
            [
              59.475249,
              18.23978
            ],
            [
              59.475482,
              18.240562
            ],
            [
              59.475507,
              18.240654
            ],
            [
              59.475551,
              18.240823
            ],
            [
              59.475635,
              18.241175
            ],
            [
              59.475693,
              18.241467
            ],
            [
              59.475719,
              18.241603
            ],
            [
              59.475797,
              18.242046
            ],
            [
              59.475873,
              18.242519
            ],
            [
              59.475934,
              18.24301
            ],
            [
              59.476004,
              18.243635
            ],
            [
              59.476044,
              18.24404
            ],
            [
              59.476095,
              18.24452
            ],
            [
              59.476134,
              18.244927
            ],
            [
              59.476169,
              18.245263
            ],
            [
              59.476228,
              18.245873
            ],
            [
              59.476296,
              18.246614
            ],
            [
              59.476329,
              18.246907
            ],
            [
              59.476357,
              18.247218
            ],
            [
              59.476433,
              18.247966
            ],
            [
              59.476492,
              18.248615
            ],
            [
              59.476568,
              18.249344
            ],
            [
              59.476683,
              18.250518
            ],
            [
              59.476737,
              18.251098
            ],
            [
              59.476799,
              18.251695
            ],
            [
              59.476921,
              18.252929
            ],
            [
              59.477004,
              18.253738
            ],
            [
              59.477015,
              18.253857
            ],
            [
              59.477033,
              18.254089
            ],
            [
              59.477045,
              18.254212
            ],
            [
              59.477119,
              18.254939
            ],
            [
              59.477184,
              18.255544
            ],
            [
              59.477235,
              18.255974
            ],
            [
              59.477251,
              18.256092
            ],
            [
              59.477273,
              18.256244
            ],
            [
              59.477323,
              18.25653
            ],
            [
              59.477376,
              18.256799
            ],
            [
              59.47745,
              18.257151
            ],
            [
              59.477486,
              18.257303
            ],
            [
              59.477598,
              18.257755
            ],
            [
              59.477617,
              18.257828
            ],
            [
              59.477739,
              18.258245
            ],
            [
              59.477829,
              18.258516
            ],
            [
              59.477943,
              18.258836
            ],
            [
              59.478005,
              18.258999
            ],
            [
              59.478108,
              18.259252
            ],
            [
              59.478202,
              18.259467
            ],
            [
              59.478315,
              18.25971
            ],
            [
              59.478366,
              18.259815
            ],
            [
              59.478403,
              18.259886
            ],
            [
              59.478833,
              18.260699
            ],
            [
              59.478985,
              18.261004
            ],
            [
              59.47912,
              18.261241
            ],
            [
              59.479265,
              18.261534
            ],
            [
              59.479486,
              18.261941
            ],
            [
              59.479889,
              18.262702
            ],
            [
              59.48015,
              18.263201
            ],
            [
              59.480248,
              18.263432
            ],
            [
              59.480341,
              18.263671
            ],
            [
              59.480429,
              18.263919
            ],
            [
              59.48051,
              18.264174
            ],
            [
              59.480586,
              18.264436
            ],
            [
              59.480655,
              18.264705
            ],
            [
              59.480718,
              18.26498
            ],
            [
              59.480775,
              18.26526
            ],
            [
              59.480825,
              18.265545
            ],
            [
              59.480869,
              18.265834
            ],
            [
              59.480905,
              18.266126
            ],
            [
              59.480935,
              18.266422
            ],
            [
              59.480941,
              18.266594
            ],
            [
              59.480941,
              18.266767
            ],
            [
              59.480938,
              18.266939
            ],
            [
              59.480923,
              18.267176
            ],
            [
              59.480895,
              18.267537
            ],
            [
              59.480789,
              18.269049
            ],
            [
              59.480773,
              18.269235
            ],
            [
              59.480697,
              18.270019
            ],
            [
              59.48066,
              18.270424
            ],
            [
              59.480588,
              18.270413
            ],
            [
              59.480436,
              18.273188
            ],
            [
              59.479988,
              18.288838
            ],
            [
              59.479969,
              18.290708
            ],
            [
              59.479713,
              18.293239
            ],
            [
              59.479485,
              18.295718
            ],
            [
              59.47913,
              18.298545
            ],
            [
              59.478979,
              18.29979
            ],
            [
              59.478973,
              18.299889
            ],
            [
              59.478605,
              18.301445
            ],
            [
              59.477714,
              18.302834
            ],
            [
              59.475676,
              18.306371
            ],
            [
              59.474379,
              18.30802
            ],
            [
              59.473967,
              18.308072
            ],
            [
              59.472618,
              18.308493
            ],
            [
              59.471987,
              18.308386
            ],
            [
              59.470442,
              18.307773
            ],
            [
              59.468703,
              18.307419
            ],
            [
              59.468737,
              18.307433
            ],
            [
              59.468252,
              18.307439
            ],
            [
              59.467356,
              18.307116
            ],
            [
              59.466585,
              18.306868
            ],
            [
              59.465827,
              18.306578
            ],
            [
              59.465511,
              18.306639
            ],
            [
              59.465221,
              18.306836
            ],
            [
              59.464916,
              18.30714
            ],
            [
              59.464561,
              18.307537
            ],
            [
              59.463055,
              18.309176
            ],
            [
              59.462208,
              18.310067
            ],
            [
              59.461859,
              18.310457
            ]
          ],
          "realtimeStatus": [
            "MONITORED"
          ],
          "isRealtimeControlled": true
        }
      ],
      "daysOfService": {
        "rvb": "0000000000000000000000000000000000000001000000000000000000000000"
      }
    },
    {
      "tripDuration": 2220,
      "tripRtDuration": 2220,
      "rating": 0,
      "isAdditional": false,
      "interchanges": 0,
      "legs": [
        {
          "infos": [
            
          ],
          "duration": 2220,
          "origin": {
            "isGlobalId": true,
            "id": "9025001000007141",
            "name": "Mörby, Danderyd",
            "disassembledName": "1",
            "type": "platform",
            "coord": [
              59.392344,
              18.047459
            ],
            "niveau": 0,
            "parent": {
              "isGlobalId": true,
              "id": "9021001007141000",
              "name": "Mörby, Danderyd",
              "disassembledName": "Mörby",
              "type": "stop",
              "parent": {
                "id": "placeID:33001062:1",
                "name": "Danderyd",
                "type": "locality"
              },
              "properties": {
                "stopId": "18007141"
              },
              "coord": [
                59.392344,
                18.047451
              ],
              "niveau": 0
            },
            "productClasses": [
              4
            ],
            "departureTimeBaseTimetable": "2026-09-01T19:00:00Z",
            "departureTimePlanned": "2026-09-01T19:00:00Z",
            "departureTimeEstimated": "2026-09-01T19:00:00Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "1",
              "occupancy": "FEW_SEATS",
              "platform": "1",
              "stoppingPointPlanned": "1",
              "platformName": "1",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "destination": {
            "isGlobalId": true,
            "id": "9025001000007091",
            "name": "Österskär, Österåker",
            "disassembledName": "1",
            "type": "platform",
            "coord": [
              59.461375,
              18.310998
            ],
            "niveau": 0,
            "parent": {
              "isGlobalId": true,
              "id": "9021001006791000",
              "name": "Österskär, Österåker",
              "disassembledName": "Österskär",
              "type": "stop",
              "parent": {
                "id": "placeID:33001017:1",
                "name": "Österåker",
                "type": "locality"
              },
              "properties": {
                "stopId": "18006791"
              },
              "coord": [
                59.460754,
                18.311582
              ],
              "niveau": 0
            },
            "productClasses": [
              4
            ],
            "arrivalTimeBaseTimetable": "2026-09-01T19:37:00Z",
            "arrivalTimePlanned": "2026-09-01T19:37:00Z",
            "arrivalTimeEstimated": "2026-09-01T19:37:00Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "1",
              "platform": "1",
              "stoppingPointPlanned": "1",
              "platformName": "1",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "transportation": {
            "id": "tfs:03028: :R:y01",
            "name": "Spårvagn Roslagsbanan 28",
            "number": "Roslagsbanan 28",
            "product": {
              "id": 7,
              "class": 4,
              "name": "Spårvagn",
              "iconId": 4
            },
            "operator": {
              "id": "1",
              "name": "Storstockholms Lokaltrafik"
            },
            "destination": {
              "id": "18006791",
              "name": "Österskär via Åkersberga",
              "type": "stop"
            },
            "properties": {
              "tripCode": 507,
              "timetablePeriod": "Current",
              "lineDisplay": "LINE",
              "globalId": "9011001002800000",
              "RealtimeTripId": "9015001002806180",
              "shortTrain": true,
              "AVMSTripID": "9015001002806180"
            },
            "isSamtrafik": false,
            "disassembledName": "28"
          },
          "stopSequence": [
            {
              "isGlobalId": true,
              "id": "9025001000007141",
              "name": "Mörby, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.392344,
                18.047459
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007141000",
                "name": "Mörby, Danderyd",
                "disassembledName": "Mörby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007141"
                },
                "coord": [
                  59.392344,
                  18.047451
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:00:00Z",
              "departureTimeEstimated": "2026-09-01T19:00:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007154",
              "name": "Djursholms Ösby, Danderyd",
              "disassembledName": "4",
              "type": "platform",
              "coord": [
                59.399053,
                18.058949
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006651000",
                "name": "Djursholms Ösby, Danderyd",
                "disassembledName": "Djursholms Ösby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006651"
                },
                "coord": [
                  59.398705,
                  18.059236
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "4",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "4",
                "platformName": "4"
              },
              "departureTimePlanned": "2026-09-01T19:02:00Z",
              "departureTimeEstimated": "2026-09-01T19:02:00Z",
              "arrivalTimePlanned": "2026-09-01T19:02:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:02:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007161",
              "name": "Bråvallavägen, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.405587,
                18.060575
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006661000",
                "name": "Bråvallavägen, Danderyd",
                "disassembledName": "Bråvallavägen",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006661"
                },
                "coord": [
                  59.405587,
                  18.060602
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:03:00Z",
              "departureTimeEstimated": "2026-09-01T19:03:00Z",
              "arrivalTimePlanned": "2026-09-01T19:03:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:03:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007171",
              "name": "Djursholms Ekeby, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.412883,
                18.05753
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007171000",
                "name": "Djursholms Ekeby, Danderyd",
                "disassembledName": "Djursholms Ekeby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007171"
                },
                "coord": [
                  59.412892,
                  18.057664
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:05:00Z",
              "departureTimeEstimated": "2026-09-01T19:05:00Z",
              "arrivalTimePlanned": "2026-09-01T19:05:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:05:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007181",
              "name": "Enebyberg, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.425899,
                18.051241
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007181000",
                "name": "Enebyberg, Danderyd",
                "disassembledName": "Enebyberg",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007181"
                },
                "coord": [
                  59.42589,
                  18.051223
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:07:00Z",
              "departureTimeEstimated": "2026-09-01T19:07:00Z",
              "arrivalTimePlanned": "2026-09-01T19:07:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:07:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007192",
              "name": "Roslags Näsby, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.435196,
                18.057413
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007191000",
                "name": "Roslags Näsby, Täby",
                "disassembledName": "Roslags Näsby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007191"
                },
                "coord": [
                  59.435219,
                  18.057395
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "2",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:10:00Z",
              "departureTimeEstimated": "2026-09-01T19:10:00Z",
              "arrivalTimePlanned": "2026-09-01T19:10:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:10:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007001",
              "name": "Täby centrum, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.444377,
                18.074678
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007001000",
                "name": "Täby centrum, Täby",
                "disassembledName": "Täby centrum",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007001"
                },
                "coord": [
                  59.444336,
                  18.074634
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:11:00Z",
              "departureTimeEstimated": "2026-09-01T19:11:00Z",
              "arrivalTimePlanned": "2026-09-01T19:11:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:11:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007011",
              "name": "Galoppfältet, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.446952,
                18.085135
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007011000",
                "name": "Galoppfältet, Täby",
                "disassembledName": "Galoppfältet",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007011"
                },
                "coord": [
                  59.446902,
                  18.085162
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:13:00Z",
              "departureTimeEstimated": "2026-09-01T19:13:00Z",
              "arrivalTimePlanned": "2026-09-01T19:13:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:13:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007023",
              "name": "Viggbyholm, Täby",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.449235,
                18.104188
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007021000",
                "name": "Viggbyholm, Täby",
                "disassembledName": "Viggbyholm",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007021"
                },
                "coord": [
                  59.449254,
                  18.104215
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "3",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T19:15:00Z",
              "departureTimeEstimated": "2026-09-01T19:15:00Z",
              "arrivalTimePlanned": "2026-09-01T19:15:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:15:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007031",
              "name": "Hägernäs, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.450884,
                18.1252
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007031000",
                "name": "Hägernäs, Täby",
                "disassembledName": "Hägernäs",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007031"
                },
                "coord": [
                  59.450916,
                  18.125227
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:18:00Z",
              "departureTimeEstimated": "2026-09-01T19:18:00Z",
              "arrivalTimePlanned": "2026-09-01T19:18:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:18:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007035",
              "name": "Arninge, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.458919,
                18.141199
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007035000",
                "name": "Arninge, Täby",
                "disassembledName": "Arninge",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007035"
                },
                "coord": [
                  59.458864,
                  18.141351
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:20:00Z",
              "departureTimeEstimated": "2026-09-01T19:20:00Z",
              "arrivalTimePlanned": "2026-09-01T19:20:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:20:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007042",
              "name": "Rydbo, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.465323,
                18.185836
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006741000",
                "name": "Rydbo, Österåker",
                "disassembledName": "Rydbo",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006741"
                },
                "coord": [
                  59.465409,
                  18.185863
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:24:00Z",
              "departureTimeEstimated": "2026-09-01T19:24:00Z",
              "arrivalTimePlanned": "2026-09-01T19:24:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:24:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007051",
              "name": "Täljö, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.473199,
                18.235441
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007051000",
                "name": "Täljö, Österåker",
                "disassembledName": "Täljö",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007051"
                },
                "coord": [
                  59.473227,
                  18.235396
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:27:00Z",
              "departureTimeEstimated": "2026-09-01T19:27:00Z",
              "arrivalTimePlanned": "2026-09-01T19:27:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:27:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007061",
              "name": "Åkers Runö, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.480618,
                18.270403
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006761000",
                "name": "Åkers Runö, Österåker",
                "disassembledName": "Åkers Runö",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006761"
                },
                "coord": [
                  59.480645,
                  18.270412
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:30:00Z",
              "departureTimeEstimated": "2026-09-01T19:30:00Z",
              "arrivalTimePlanned": "2026-09-01T19:30:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:30:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007071",
              "name": "Åkersberga, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.479016,
                18.299769
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007071000",
                "name": "Åkersberga, Österåker",
                "disassembledName": "Åkersberga",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007071"
                },
                "coord": [
                  59.479003,
                  18.299778
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:33:00Z",
              "departureTimeEstimated": "2026-09-01T19:33:00Z",
              "arrivalTimePlanned": "2026-09-01T19:33:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:33:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007081",
              "name": "Tunagård, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.468746,
                18.307432
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006781000",
                "name": "Tunagård, Österåker",
                "disassembledName": "Tunagård",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006781"
                },
                "coord": [
                  59.468755,
                  18.307306
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:34:00Z",
              "departureTimeEstimated": "2026-09-01T19:34:00Z",
              "arrivalTimePlanned": "2026-09-01T19:34:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:34:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007091",
              "name": "Österskär, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.461375,
                18.310998
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006791000",
                "name": "Österskär, Österåker",
                "disassembledName": "Österskär",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006791"
                },
                "coord": [
                  59.460754,
                  18.311582
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "arrivalTimePlanned": "2026-09-01T19:37:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:37:00Z"
            }
          ],
          "properties": {
            "tripId": "9015001002806180"
          },
          "hints": [
            {
              "type": "Timetable",
              "providerCode": "3G",
              "content": "Cykel tillåten på avgången, ej elcykel. Cyklar ska placeras vid anvisad plats. Läs mer på sl.se.",
              "properties": {
                "subnet": "tfs"
              }
            }
          ],
          "coords": [
            [
              59.39234,
              18.04745
            ],
            [
              59.392442,
              18.047565
            ],
            [
              59.392495,
              18.04763
            ],
            [
              59.392731,
              18.047947
            ],
            [
              59.392817,
              18.048069
            ],
            [
              59.39304,
              18.048398
            ],
            [
              59.393088,
              18.04848
            ],
            [
              59.393278,
              18.048814
            ],
            [
              59.393522,
              18.049264
            ],
            [
              59.393846,
              18.049954
            ],
            [
              59.393887,
              18.050049
            ],
            [
              59.394154,
              18.050715
            ],
            [
              59.394208,
              18.05087
            ],
            [
              59.394497,
              18.051747
            ],
            [
              59.394544,
              18.051909
            ],
            [
              59.394755,
              18.052653
            ],
            [
              59.39499,
              18.053527
            ],
            [
              59.395274,
              18.054701
            ],
            [
              59.395519,
              18.055576
            ],
            [
              59.395541,
              18.055647
            ],
            [
              59.395573,
              18.055733
            ],
            [
              59.395719,
              18.056124
            ],
            [
              59.395752,
              18.056207
            ],
            [
              59.395795,
              18.056301
            ],
            [
              59.395948,
              18.056621
            ],
            [
              59.395993,
              18.056712
            ],
            [
              59.396024,
              18.056768
            ],
            [
              59.396178,
              18.057026
            ],
            [
              59.396212,
              18.057075
            ],
            [
              59.396266,
              18.057142
            ],
            [
              59.39661,
              18.05756
            ],
            [
              59.397,
              18.057973
            ],
            [
              59.397038,
              18.058008
            ],
            [
              59.397068,
              18.058032
            ],
            [
              59.397709,
              18.058496
            ],
            [
              59.3979,
              18.058538
            ],
            [
              59.397963,
              18.058555
            ],
            [
              59.398515,
              18.058774
            ],
            [
              59.398578,
              18.058795
            ],
            [
              59.39905,
              18.058897
            ],
            [
              59.39905,
              18.058951
            ],
            [
              59.399256,
              18.058991
            ],
            [
              59.400742,
              18.059221
            ],
            [
              59.401899,
              18.059356
            ],
            [
              59.403262,
              18.059482
            ],
            [
              59.403923,
              18.059698
            ],
            [
              59.404431,
              18.059914
            ],
            [
              59.405355,
              18.060486
            ],
            [
              59.405585,
              18.06057
            ],
            [
              59.406292,
              18.06083
            ],
            [
              59.406862,
              18.060778
            ],
            [
              59.408775,
              18.059807
            ],
            [
              59.409923,
              18.059177
            ],
            [
              59.412893,
              18.057672
            ],
            [
              59.413371,
              18.057429
            ],
            [
              59.414074,
              18.056992
            ],
            [
              59.414383,
              18.056679
            ],
            [
              59.414698,
              18.056195
            ],
            [
              59.415005,
              18.055596
            ],
            [
              59.415388,
              18.054673
            ],
            [
              59.415972,
              18.053422
            ],
            [
              59.416373,
              18.052807
            ],
            [
              59.416832,
              18.052241
            ],
            [
              59.41734,
              18.051728
            ],
            [
              59.419029,
              18.050202
            ],
            [
              59.419526,
              18.049941
            ],
            [
              59.42,
              18.049792
            ],
            [
              59.420687,
              18.049822
            ],
            [
              59.421287,
              18.049968
            ],
            [
              59.421996,
              18.050213
            ],
            [
              59.423688,
              18.051235
            ],
            [
              59.424447,
              18.051235
            ],
            [
              59.425219,
              18.051221
            ],
            [
              59.425894,
              18.051237
            ],
            [
              59.425975,
              18.051239
            ],
            [
              59.426573,
              18.051043
            ],
            [
              59.429686,
              18.051108
            ],
            [
              59.430157,
              18.051235
            ],
            [
              59.430588,
              18.051387
            ],
            [
              59.430924,
              18.051575
            ],
            [
              59.431227,
              18.051784
            ],
            [
              59.43149,
              18.052004
            ],
            [
              59.432089,
              18.05257
            ],
            [
              59.432696,
              18.053237
            ],
            [
              59.432853,
              18.05346
            ],
            [
              59.433005,
              18.053715
            ],
            [
              59.4345,
              18.056329
            ],
            [
              59.435069,
              18.057197
            ],
            [
              59.435198,
              18.057416
            ],
            [
              59.435272,
              18.057542
            ],
            [
              59.435627,
              18.058066
            ],
            [
              59.436154,
              18.058596
            ],
            [
              59.436817,
              18.059265
            ],
            [
              59.437021,
              18.059497
            ],
            [
              59.43739,
              18.05997
            ],
            [
              59.437752,
              18.060508
            ],
            [
              59.438172,
              18.061259
            ],
            [
              59.440956,
              18.067235
            ],
            [
              59.441976,
              18.069362
            ],
            [
              59.442471,
              18.070576
            ],
            [
              59.443483,
              18.072734
            ],
            [
              59.444262,
              18.0744
            ],
            [
              59.44438,
              18.074691
            ],
            [
              59.44438,
              18.07469
            ],
            [
              59.444519,
              18.075031
            ],
            [
              59.444556,
              18.075132
            ],
            [
              59.444741,
              18.075672
            ],
            [
              59.444774,
              18.07578
            ],
            [
              59.445716,
              18.079265
            ],
            [
              59.446307,
              18.081624
            ],
            [
              59.446383,
              18.081935
            ],
            [
              59.446472,
              18.082338
            ],
            [
              59.446557,
              18.082709
            ],
            [
              59.446706,
              18.083406
            ],
            [
              59.446731,
              18.083529
            ],
            [
              59.446746,
              18.083608
            ],
            [
              59.446785,
              18.083847
            ],
            [
              59.446831,
              18.084192
            ],
            [
              59.44689,
              18.084704
            ],
            [
              59.446934,
              18.085136
            ],
            [
              59.446944,
              18.085243
            ],
            [
              59.446973,
              18.085602
            ],
            [
              59.447094,
              18.087033
            ],
            [
              59.447291,
              18.089118
            ],
            [
              59.447376,
              18.089998
            ],
            [
              59.447486,
              18.091157
            ],
            [
              59.447739,
              18.093984
            ],
            [
              59.447786,
              18.09454
            ],
            [
              59.447844,
              18.095138
            ],
            [
              59.447986,
              18.0968
            ],
            [
              59.448144,
              18.09871
            ],
            [
              59.448164,
              18.098903
            ],
            [
              59.448204,
              18.099351
            ],
            [
              59.448244,
              18.09978
            ],
            [
              59.448277,
              18.100105
            ],
            [
              59.448287,
              18.100206
            ],
            [
              59.448348,
              18.100711
            ],
            [
              59.448375,
              18.100908
            ],
            [
              59.448435,
              18.101299
            ],
            [
              59.448561,
              18.10198
            ],
            [
              59.448588,
              18.102113
            ],
            [
              59.448628,
              18.102281
            ],
            [
              59.448695,
              18.102539
            ],
            [
              59.448731,
              18.102666
            ],
            [
              59.448793,
              18.102878
            ],
            [
              59.448821,
              18.102965
            ],
            [
              59.448839,
              18.103017
            ],
            [
              59.448946,
              18.103308
            ],
            [
              59.449062,
              18.103631
            ],
            [
              59.449268,
              18.104143
            ],
            [
              59.449476,
              18.104656
            ],
            [
              59.449722,
              18.105214
            ],
            [
              59.449776,
              18.105317
            ],
            [
              59.45015,
              18.105984
            ],
            [
              59.450288,
              18.106222
            ],
            [
              59.450337,
              18.106303
            ],
            [
              59.450658,
              18.106753
            ],
            [
              59.451112,
              18.107436
            ],
            [
              59.451406,
              18.107944
            ],
            [
              59.451791,
              18.108556
            ],
            [
              59.452221,
              18.109294
            ],
            [
              59.452323,
              18.109486
            ],
            [
              59.452401,
              18.109641
            ],
            [
              59.452428,
              18.1097
            ],
            [
              59.452461,
              18.109779
            ],
            [
              59.452537,
              18.109975
            ],
            [
              59.45258,
              18.110092
            ],
            [
              59.452701,
              18.110477
            ],
            [
              59.452786,
              18.110779
            ],
            [
              59.4528,
              18.110834
            ],
            [
              59.452815,
              18.110905
            ],
            [
              59.452877,
              18.111233
            ],
            [
              59.452902,
              18.111394
            ],
            [
              59.452928,
              18.111571
            ],
            [
              59.452952,
              18.111745
            ],
            [
              59.452962,
              18.111846
            ],
            [
              59.452981,
              18.112135
            ],
            [
              59.452994,
              18.112432
            ],
            [
              59.452998,
              18.112619
            ],
            [
              59.452996,
              18.11286
            ],
            [
              59.452988,
              18.113108
            ],
            [
              59.45298,
              18.113232
            ],
            [
              59.452939,
              18.113677
            ],
            [
              59.452922,
              18.113814
            ],
            [
              59.452875,
              18.11409
            ],
            [
              59.452805,
              18.114442
            ],
            [
              59.452709,
              18.114872
            ],
            [
              59.45257,
              18.11548
            ],
            [
              59.452376,
              18.116375
            ],
            [
              59.452352,
              18.11649
            ],
            [
              59.452252,
              18.117013
            ],
            [
              59.452133,
              18.117728
            ],
            [
              59.452111,
              18.117868
            ],
            [
              59.452043,
              18.118354
            ],
            [
              59.451945,
              18.119091
            ],
            [
              59.451773,
              18.12029
            ],
            [
              59.451685,
              18.120881
            ],
            [
              59.45162,
              18.121352
            ],
            [
              59.451523,
              18.121962
            ],
            [
              59.451364,
              18.122982
            ],
            [
              59.451304,
              18.123337
            ],
            [
              59.45126,
              18.123573
            ],
            [
              59.451221,
              18.123768
            ],
            [
              59.451102,
              18.124337
            ],
            [
              59.451069,
              18.124488
            ],
            [
              59.45099,
              18.124833
            ],
            [
              59.450896,
              18.125213
            ],
            [
              59.45067,
              18.126074
            ],
            [
              59.450586,
              18.126368
            ],
            [
              59.450447,
              18.126839
            ],
            [
              59.450246,
              18.127567
            ],
            [
              59.450095,
              18.128088
            ],
            [
              59.450065,
              18.128197
            ],
            [
              59.450036,
              18.128323
            ],
            [
              59.450009,
              18.128451
            ],
            [
              59.449908,
              18.128976
            ],
            [
              59.449852,
              18.129292
            ],
            [
              59.449835,
              18.129412
            ],
            [
              59.449818,
              18.129554
            ],
            [
              59.449801,
              18.129733
            ],
            [
              59.449793,
              18.129852
            ],
            [
              59.44979,
              18.13
            ],
            [
              59.44979,
              18.130147
            ],
            [
              59.449796,
              18.130407
            ],
            [
              59.449804,
              18.130559
            ],
            [
              59.449814,
              18.130698
            ],
            [
              59.44986,
              18.131237
            ],
            [
              59.449878,
              18.131399
            ],
            [
              59.449886,
              18.131457
            ],
            [
              59.449902,
              18.131547
            ],
            [
              59.450026,
              18.132161
            ],
            [
              59.450072,
              18.132338
            ],
            [
              59.450111,
              18.132477
            ],
            [
              59.450179,
              18.132683
            ],
            [
              59.450221,
              18.132801
            ],
            [
              59.450259,
              18.1329
            ],
            [
              59.450293,
              18.132979
            ],
            [
              59.450465,
              18.133348
            ],
            [
              59.450519,
              18.133448
            ],
            [
              59.450657,
              18.133679
            ],
            [
              59.450708,
              18.133759
            ],
            [
              59.450912,
              18.13402
            ],
            [
              59.45103,
              18.134152
            ],
            [
              59.451085,
              18.13421
            ],
            [
              59.452101,
              18.1351
            ],
            [
              59.453436,
              18.136211
            ],
            [
              59.45358,
              18.136324
            ],
            [
              59.454218,
              18.136877
            ],
            [
              59.454887,
              18.137444
            ],
            [
              59.455072,
              18.137619
            ],
            [
              59.455412,
              18.137915
            ],
            [
              59.457123,
              18.139547
            ],
            [
              59.45769,
              18.140161
            ],
            [
              59.458179,
              18.140801
            ],
            [
              59.4588,
              18.14157
            ],
            [
              59.458823,
              18.141612
            ],
            [
              59.459633,
              18.142703
            ],
            [
              59.460273,
              18.143721
            ],
            [
              59.461317,
              18.145282
            ],
            [
              59.461747,
              18.146031
            ],
            [
              59.462401,
              18.147983
            ],
            [
              59.463216,
              18.152164
            ],
            [
              59.463522,
              18.154022
            ],
            [
              59.464183,
              18.157238
            ],
            [
              59.465068,
              18.160475
            ],
            [
              59.465479,
              18.161938
            ],
            [
              59.465602,
              18.162231
            ],
            [
              59.46575,
              18.16256
            ],
            [
              59.465787,
              18.162635
            ],
            [
              59.465912,
              18.162862
            ],
            [
              59.466087,
              18.163165
            ],
            [
              59.466297,
              18.16351
            ],
            [
              59.466616,
              18.163957
            ],
            [
              59.466882,
              18.164335
            ],
            [
              59.466941,
              18.164423
            ],
            [
              59.467225,
              18.164919
            ],
            [
              59.467284,
              18.165041
            ],
            [
              59.467443,
              18.165385
            ],
            [
              59.467499,
              18.165511
            ],
            [
              59.467671,
              18.165922
            ],
            [
              59.467698,
              18.165993
            ],
            [
              59.467726,
              18.166081
            ],
            [
              59.467795,
              18.166319
            ],
            [
              59.467917,
              18.166758
            ],
            [
              59.468014,
              18.167127
            ],
            [
              59.468044,
              18.16726
            ],
            [
              59.468089,
              18.167472
            ],
            [
              59.468103,
              18.167549
            ],
            [
              59.468124,
              18.167684
            ],
            [
              59.468143,
              18.16782
            ],
            [
              59.468184,
              18.168147
            ],
            [
              59.468222,
              18.168493
            ],
            [
              59.468239,
              18.168675
            ],
            [
              59.468273,
              18.169097
            ],
            [
              59.468297,
              18.169499
            ],
            [
              59.468307,
              18.169739
            ],
            [
              59.468312,
              18.169878
            ],
            [
              59.468315,
              18.17004
            ],
            [
              59.468316,
              18.170162
            ],
            [
              59.468316,
              18.170286
            ],
            [
              59.468312,
              18.170451
            ],
            [
              59.468302,
              18.170597
            ],
            [
              59.46828,
              18.170866
            ],
            [
              59.468238,
              18.171333
            ],
            [
              59.468189,
              18.171768
            ],
            [
              59.468136,
              18.172225
            ],
            [
              59.468064,
              18.172725
            ],
            [
              59.468004,
              18.173105
            ],
            [
              59.467909,
              18.173676
            ],
            [
              59.467799,
              18.174265
            ],
            [
              59.467693,
              18.174786
            ],
            [
              59.467577,
              18.175321
            ],
            [
              59.467532,
              18.17551
            ],
            [
              59.467283,
              18.176457
            ],
            [
              59.467242,
              18.176604
            ],
            [
              59.466751,
              18.178202
            ],
            [
              59.466342,
              18.179555
            ],
            [
              59.466094,
              18.180451
            ],
            [
              59.466059,
              18.1806
            ],
            [
              59.465994,
              18.180901
            ],
            [
              59.465859,
              18.181564
            ],
            [
              59.465727,
              18.182285
            ],
            [
              59.465665,
              18.182672
            ],
            [
              59.465621,
              18.182971
            ],
            [
              59.4656,
              18.183131
            ],
            [
              59.465565,
              18.183427
            ],
            [
              59.46553,
              18.183762
            ],
            [
              59.465459,
              18.184572
            ],
            [
              59.465444,
              18.184806
            ],
            [
              59.46541,
              18.185302
            ],
            [
              59.46539,
              18.185709
            ],
            [
              59.465385,
              18.185855
            ],
            [
              59.465367,
              18.186534
            ],
            [
              59.465368,
              18.186744
            ],
            [
              59.465371,
              18.187033
            ],
            [
              59.465377,
              18.187339
            ],
            [
              59.465387,
              18.187677
            ],
            [
              59.465432,
              18.188531
            ],
            [
              59.465464,
              18.188955
            ],
            [
              59.465494,
              18.189278
            ],
            [
              59.465505,
              18.18938
            ],
            [
              59.465571,
              18.189949
            ],
            [
              59.465637,
              18.190418
            ],
            [
              59.465673,
              18.190645
            ],
            [
              59.465728,
              18.191029
            ],
            [
              59.465762,
              18.191228
            ],
            [
              59.4659,
              18.191974
            ],
            [
              59.465975,
              18.192339
            ],
            [
              59.466043,
              18.192635
            ],
            [
              59.466097,
              18.192858
            ],
            [
              59.466158,
              18.1931
            ],
            [
              59.466232,
              18.193379
            ],
            [
              59.466252,
              18.193453
            ],
            [
              59.46636,
              18.193819
            ],
            [
              59.466493,
              18.194283
            ],
            [
              59.466689,
              18.194939
            ],
            [
              59.46682,
              18.195362
            ],
            [
              59.466959,
              18.195827
            ],
            [
              59.467472,
              18.197512
            ],
            [
              59.467523,
              18.197675
            ],
            [
              59.467712,
              18.198264
            ],
            [
              59.467907,
              18.198911
            ],
            [
              59.467951,
              18.199079
            ],
            [
              59.468258,
              18.20029
            ],
            [
              59.4684,
              18.200933
            ],
            [
              59.468431,
              18.201082
            ],
            [
              59.468492,
              18.201394
            ],
            [
              59.468631,
              18.20214
            ],
            [
              59.468677,
              18.202426
            ],
            [
              59.468762,
              18.203016
            ],
            [
              59.468804,
              18.20332
            ],
            [
              59.468854,
              18.203717
            ],
            [
              59.468904,
              18.20414
            ],
            [
              59.468957,
              18.204536
            ],
            [
              59.469001,
              18.204843
            ],
            [
              59.469111,
              18.205804
            ],
            [
              59.469206,
              18.20656
            ],
            [
              59.469313,
              18.207471
            ],
            [
              59.469347,
              18.207775
            ],
            [
              59.469359,
              18.207897
            ],
            [
              59.469411,
              18.208472
            ],
            [
              59.46945,
              18.20893
            ],
            [
              59.469482,
              18.209373
            ],
            [
              59.469509,
              18.209914
            ],
            [
              59.469532,
              18.210615
            ],
            [
              59.469543,
              18.211945
            ],
            [
              59.469526,
              18.212486
            ],
            [
              59.469441,
              18.214147
            ],
            [
              59.469361,
              18.215391
            ],
            [
              59.469392,
              18.215397
            ],
            [
              59.469377,
              18.215568
            ],
            [
              59.469357,
              18.21577
            ],
            [
              59.469331,
              18.215987
            ],
            [
              59.469275,
              18.217747
            ],
            [
              59.469185,
              18.220115
            ],
            [
              59.469171,
              18.221082
            ],
            [
              59.469182,
              18.221807
            ],
            [
              59.469205,
              18.222654
            ],
            [
              59.469241,
              18.223234
            ],
            [
              59.469289,
              18.223839
            ],
            [
              59.469362,
              18.224395
            ],
            [
              59.469435,
              18.225024
            ],
            [
              59.469508,
              18.225411
            ],
            [
              59.469581,
              18.225968
            ],
            [
              59.469703,
              18.226645
            ],
            [
              59.469837,
              18.227178
            ],
            [
              59.470033,
              18.228074
            ],
            [
              59.470265,
              18.228776
            ],
            [
              59.470497,
              18.229648
            ],
            [
              59.470754,
              18.230278
            ],
            [
              59.471,
              18.230812
            ],
            [
              59.471118,
              18.23108
            ],
            [
              59.471183,
              18.231193
            ],
            [
              59.47126,
              18.231349
            ],
            [
              59.471247,
              18.231374
            ],
            [
              59.471299,
              18.231395
            ],
            [
              59.471404,
              18.231614
            ],
            [
              59.472425,
              18.233702
            ],
            [
              59.472531,
              18.233923
            ],
            [
              59.472753,
              18.234374
            ],
            [
              59.473232,
              18.235367
            ],
            [
              59.473369,
              18.23565
            ],
            [
              59.473577,
              18.23607
            ],
            [
              59.473977,
              18.236867
            ],
            [
              59.474082,
              18.237087
            ],
            [
              59.47445,
              18.237813
            ],
            [
              59.474571,
              18.238061
            ],
            [
              59.474668,
              18.238272
            ],
            [
              59.474791,
              18.238558
            ],
            [
              59.475026,
              18.239131
            ],
            [
              59.475062,
              18.239229
            ],
            [
              59.475249,
              18.23978
            ],
            [
              59.475482,
              18.240562
            ],
            [
              59.475507,
              18.240654
            ],
            [
              59.475551,
              18.240823
            ],
            [
              59.475635,
              18.241175
            ],
            [
              59.475693,
              18.241467
            ],
            [
              59.475719,
              18.241603
            ],
            [
              59.475797,
              18.242046
            ],
            [
              59.475873,
              18.242519
            ],
            [
              59.475934,
              18.24301
            ],
            [
              59.476004,
              18.243635
            ],
            [
              59.476044,
              18.24404
            ],
            [
              59.476095,
              18.24452
            ],
            [
              59.476134,
              18.244927
            ],
            [
              59.476169,
              18.245263
            ],
            [
              59.476228,
              18.245873
            ],
            [
              59.476296,
              18.246614
            ],
            [
              59.476329,
              18.246907
            ],
            [
              59.476357,
              18.247218
            ],
            [
              59.476433,
              18.247966
            ],
            [
              59.476492,
              18.248615
            ],
            [
              59.476568,
              18.249344
            ],
            [
              59.476683,
              18.250518
            ],
            [
              59.476737,
              18.251098
            ],
            [
              59.476799,
              18.251695
            ],
            [
              59.476921,
              18.252929
            ],
            [
              59.477004,
              18.253738
            ],
            [
              59.477015,
              18.253857
            ],
            [
              59.477033,
              18.254089
            ],
            [
              59.477045,
              18.254212
            ],
            [
              59.477119,
              18.254939
            ],
            [
              59.477184,
              18.255544
            ],
            [
              59.477235,
              18.255974
            ],
            [
              59.477251,
              18.256092
            ],
            [
              59.477273,
              18.256244
            ],
            [
              59.477323,
              18.25653
            ],
            [
              59.477376,
              18.256799
            ],
            [
              59.47745,
              18.257151
            ],
            [
              59.477486,
              18.257303
            ],
            [
              59.477598,
              18.257755
            ],
            [
              59.477617,
              18.257828
            ],
            [
              59.477739,
              18.258245
            ],
            [
              59.477829,
              18.258516
            ],
            [
              59.477943,
              18.258836
            ],
            [
              59.478005,
              18.258999
            ],
            [
              59.478108,
              18.259252
            ],
            [
              59.478202,
              18.259467
            ],
            [
              59.478315,
              18.25971
            ],
            [
              59.478366,
              18.259815
            ],
            [
              59.478403,
              18.259886
            ],
            [
              59.478833,
              18.260699
            ],
            [
              59.478985,
              18.261004
            ],
            [
              59.47912,
              18.261241
            ],
            [
              59.479265,
              18.261534
            ],
            [
              59.479486,
              18.261941
            ],
            [
              59.479889,
              18.262702
            ],
            [
              59.48015,
              18.263201
            ],
            [
              59.480248,
              18.263432
            ],
            [
              59.480341,
              18.263671
            ],
            [
              59.480429,
              18.263919
            ],
            [
              59.48051,
              18.264174
            ],
            [
              59.480586,
              18.264436
            ],
            [
              59.480655,
              18.264705
            ],
            [
              59.480718,
              18.26498
            ],
            [
              59.480775,
              18.26526
            ],
            [
              59.480825,
              18.265545
            ],
            [
              59.480869,
              18.265834
            ],
            [
              59.480905,
              18.266126
            ],
            [
              59.480935,
              18.266422
            ],
            [
              59.480941,
              18.266594
            ],
            [
              59.480941,
              18.266767
            ],
            [
              59.480938,
              18.266939
            ],
            [
              59.480923,
              18.267176
            ],
            [
              59.480895,
              18.267537
            ],
            [
              59.480789,
              18.269049
            ],
            [
              59.480773,
              18.269235
            ],
            [
              59.480697,
              18.270019
            ],
            [
              59.48066,
              18.270424
            ],
            [
              59.480588,
              18.270413
            ],
            [
              59.480436,
              18.273188
            ],
            [
              59.479988,
              18.288838
            ],
            [
              59.479969,
              18.290708
            ],
            [
              59.479713,
              18.293239
            ],
            [
              59.479485,
              18.295718
            ],
            [
              59.47913,
              18.298545
            ],
            [
              59.478979,
              18.29979
            ],
            [
              59.478973,
              18.299889
            ],
            [
              59.478605,
              18.301445
            ],
            [
              59.477714,
              18.302834
            ],
            [
              59.475676,
              18.306371
            ],
            [
              59.474379,
              18.30802
            ],
            [
              59.473967,
              18.308072
            ],
            [
              59.472618,
              18.308493
            ],
            [
              59.471987,
              18.308386
            ],
            [
              59.470442,
              18.307773
            ],
            [
              59.468703,
              18.307419
            ],
            [
              59.468737,
              18.307433
            ],
            [
              59.468252,
              18.307439
            ],
            [
              59.467356,
              18.307116
            ],
            [
              59.466585,
              18.306868
            ],
            [
              59.465827,
              18.306578
            ],
            [
              59.465511,
              18.306639
            ],
            [
              59.465221,
              18.306836
            ],
            [
              59.464916,
              18.30714
            ],
            [
              59.464561,
              18.307537
            ],
            [
              59.463055,
              18.309176
            ],
            [
              59.462208,
              18.310067
            ],
            [
              59.461859,
              18.310457
            ]
          ],
          "realtimeStatus": [
            "MONITORED"
          ],
          "isRealtimeControlled": true
        }
      ],
      "daysOfService": {
        "rvb": "0000000000000000000000004F9F000039F3E7CF3E7CF9F327CF9F3E000007CF"
      }
    },
    {
      "tripDuration": 2220,
      "tripRtDuration": 2220,
      "rating": 0,
      "isAdditional": false,
      "interchanges": 0,
      "legs": [
        {
          "infos": [
            
          ],
          "duration": 2220,
          "origin": {
            "isGlobalId": true,
            "id": "9025001000007141",
            "name": "Mörby, Danderyd",
            "disassembledName": "1",
            "type": "platform",
            "coord": [
              59.392344,
              18.047459
            ],
            "niveau": 0,
            "parent": {
              "isGlobalId": true,
              "id": "9021001007141000",
              "name": "Mörby, Danderyd",
              "disassembledName": "Mörby",
              "type": "stop",
              "parent": {
                "id": "placeID:33001062:1",
                "name": "Danderyd",
                "type": "locality"
              },
              "properties": {
                "stopId": "18007141"
              },
              "coord": [
                59.392344,
                18.047451
              ],
              "niveau": 0
            },
            "productClasses": [
              4
            ],
            "departureTimeBaseTimetable": "2026-09-01T19:30:00Z",
            "departureTimePlanned": "2026-09-01T19:30:00Z",
            "departureTimeEstimated": "2026-09-01T19:30:00Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "1",
              "occupancy": "FEW_SEATS",
              "platform": "1",
              "stoppingPointPlanned": "1",
              "platformName": "1",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "destination": {
            "isGlobalId": true,
            "id": "9025001000007091",
            "name": "Österskär, Österåker",
            "disassembledName": "1",
            "type": "platform",
            "coord": [
              59.461375,
              18.310998
            ],
            "niveau": 0,
            "parent": {
              "isGlobalId": true,
              "id": "9021001006791000",
              "name": "Österskär, Österåker",
              "disassembledName": "Österskär",
              "type": "stop",
              "parent": {
                "id": "placeID:33001017:1",
                "name": "Österåker",
                "type": "locality"
              },
              "properties": {
                "stopId": "18006791"
              },
              "coord": [
                59.460754,
                18.311582
              ],
              "niveau": 0
            },
            "productClasses": [
              4
            ],
            "arrivalTimeBaseTimetable": "2026-09-01T20:07:00Z",
            "arrivalTimePlanned": "2026-09-01T20:07:00Z",
            "arrivalTimeEstimated": "2026-09-01T20:07:00Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "1",
              "platform": "1",
              "stoppingPointPlanned": "1",
              "platformName": "1",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "transportation": {
            "id": "tfs:03028: :R:y01",
            "name": "Spårvagn Roslagsbanan 28",
            "number": "Roslagsbanan 28",
            "product": {
              "id": 7,
              "class": 4,
              "name": "Spårvagn",
              "iconId": 4
            },
            "operator": {
              "id": "1",
              "name": "Storstockholms Lokaltrafik"
            },
            "destination": {
              "id": "18006791",
              "name": "Österskär via Åkersberga",
              "type": "stop"
            },
            "properties": {
              "tripCode": 508,
              "timetablePeriod": "Current",
              "lineDisplay": "LINE",
              "globalId": "9011001002800000",
              "RealtimeTripId": "9015001002806182",
              "shortTrain": true
            },
            "isSamtrafik": false,
            "disassembledName": "28"
          },
          "stopSequence": [
            {
              "isGlobalId": true,
              "id": "9025001000007141",
              "name": "Mörby, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.392344,
                18.047459
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007141000",
                "name": "Mörby, Danderyd",
                "disassembledName": "Mörby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007141"
                },
                "coord": [
                  59.392344,
                  18.047451
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:30:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007154",
              "name": "Djursholms Ösby, Danderyd",
              "disassembledName": "4",
              "type": "platform",
              "coord": [
                59.399053,
                18.058949
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006651000",
                "name": "Djursholms Ösby, Danderyd",
                "disassembledName": "Djursholms Ösby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006651"
                },
                "coord": [
                  59.398705,
                  18.059236
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "4",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "4",
                "platformName": "4"
              },
              "departureTimePlanned": "2026-09-01T19:32:00Z",
              "arrivalTimePlanned": "2026-09-01T19:32:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007161",
              "name": "Bråvallavägen, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.405587,
                18.060575
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006661000",
                "name": "Bråvallavägen, Danderyd",
                "disassembledName": "Bråvallavägen",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006661"
                },
                "coord": [
                  59.405587,
                  18.060602
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:33:00Z",
              "arrivalTimePlanned": "2026-09-01T19:33:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007171",
              "name": "Djursholms Ekeby, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.412883,
                18.05753
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007171000",
                "name": "Djursholms Ekeby, Danderyd",
                "disassembledName": "Djursholms Ekeby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007171"
                },
                "coord": [
                  59.412892,
                  18.057664
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:35:00Z",
              "arrivalTimePlanned": "2026-09-01T19:35:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007181",
              "name": "Enebyberg, Danderyd",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.425899,
                18.051241
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007181000",
                "name": "Enebyberg, Danderyd",
                "disassembledName": "Enebyberg",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001062:1",
                  "name": "Danderyd",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007181"
                },
                "coord": [
                  59.42589,
                  18.051223
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:37:00Z",
              "arrivalTimePlanned": "2026-09-01T19:37:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007192",
              "name": "Roslags Näsby, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.435196,
                18.057413
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007191000",
                "name": "Roslags Näsby, Täby",
                "disassembledName": "Roslags Näsby",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007191"
                },
                "coord": [
                  59.435219,
                  18.057395
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "2",
                "occupancy": "FEW_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:40:00Z",
              "arrivalTimePlanned": "2026-09-01T19:40:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007001",
              "name": "Täby centrum, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.444377,
                18.074678
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007001000",
                "name": "Täby centrum, Täby",
                "disassembledName": "Täby centrum",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007001"
                },
                "coord": [
                  59.444336,
                  18.074634
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:41:00Z",
              "arrivalTimePlanned": "2026-09-01T19:41:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007011",
              "name": "Galoppfältet, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.446952,
                18.085135
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007011000",
                "name": "Galoppfältet, Täby",
                "disassembledName": "Galoppfältet",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007011"
                },
                "coord": [
                  59.446902,
                  18.085162
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:43:00Z",
              "arrivalTimePlanned": "2026-09-01T19:43:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007023",
              "name": "Viggbyholm, Täby",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.449235,
                18.104188
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007021000",
                "name": "Viggbyholm, Täby",
                "disassembledName": "Viggbyholm",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007021"
                },
                "coord": [
                  59.449254,
                  18.104215
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "3",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T19:45:00Z",
              "arrivalTimePlanned": "2026-09-01T19:45:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007031",
              "name": "Hägernäs, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.450884,
                18.1252
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007031000",
                "name": "Hägernäs, Täby",
                "disassembledName": "Hägernäs",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007031"
                },
                "coord": [
                  59.450916,
                  18.125227
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:48:00Z",
              "arrivalTimePlanned": "2026-09-01T19:48:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007035",
              "name": "Arninge, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.458919,
                18.141199
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007035000",
                "name": "Arninge, Täby",
                "disassembledName": "Arninge",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001060:1",
                  "name": "Täby",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007035"
                },
                "coord": [
                  59.458864,
                  18.141351
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:50:00Z",
              "arrivalTimePlanned": "2026-09-01T19:50:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007042",
              "name": "Rydbo, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.465323,
                18.185836
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006741000",
                "name": "Rydbo, Österåker",
                "disassembledName": "Rydbo",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006741"
                },
                "coord": [
                  59.465409,
                  18.185863
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:54:00Z",
              "arrivalTimePlanned": "2026-09-01T19:54:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007051",
              "name": "Täljö, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.473199,
                18.235441
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007051000",
                "name": "Täljö, Österåker",
                "disassembledName": "Täljö",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007051"
                },
                "coord": [
                  59.473227,
                  18.235396
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:57:00Z",
              "arrivalTimePlanned": "2026-09-01T19:57:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007061",
              "name": "Åkers Runö, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.480618,
                18.270403
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006761000",
                "name": "Åkers Runö, Österåker",
                "disassembledName": "Åkers Runö",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006761"
                },
                "coord": [
                  59.480645,
                  18.270412
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T20:00:00Z",
              "arrivalTimePlanned": "2026-09-01T20:00:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007071",
              "name": "Åkersberga, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.479016,
                18.299769
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001007071000",
                "name": "Åkersberga, Österåker",
                "disassembledName": "Åkersberga",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18007071"
                },
                "coord": [
                  59.479003,
                  18.299778
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T20:03:00Z",
              "arrivalTimePlanned": "2026-09-01T20:03:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007081",
              "name": "Tunagård, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.468746,
                18.307432
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006781000",
                "name": "Tunagård, Österåker",
                "disassembledName": "Tunagård",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006781"
                },
                "coord": [
                  59.468755,
                  18.307306
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T20:04:00Z",
              "arrivalTimePlanned": "2026-09-01T20:04:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007091",
              "name": "Österskär, Österåker",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.461375,
                18.310998
              ],
              "niveau": 0,
              "parent": {
                "isGlobalId": true,
                "id": "9021001006791000",
                "name": "Österskär, Österåker",
                "disassembledName": "Österskär",
                "type": "stop",
                "parent": {
                  "id": "placeID:33001017:1",
                  "name": "Österåker",
                  "type": "locality"
                },
                "properties": {
                  "stopId": "18006791"
                },
                "coord": [
                  59.460754,
                  18.311582
                ],
                "niveau": 0
              },
              "productClasses": [
                4
              ],
              "properties": {
                "AREA_NIVEAU_DIVA": "0",
                "area": "1",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "arrivalTimePlanned": "2026-09-01T20:07:00Z"
            }
          ],
          "properties": {
            "tripId": "9015001002806182"
          },
          "hints": [
            {
              "type": "Timetable",
              "providerCode": "3G",
              "content": "Cykel tillåten på avgången, ej elcykel. Cyklar ska placeras vid anvisad plats. Läs mer på sl.se.",
              "properties": {
                "subnet": "tfs"
              }
            }
          ],
          "coords": [
            [
              59.39234,
              18.04745
            ],
            [
              59.392442,
              18.047565
            ],
            [
              59.392495,
              18.04763
            ],
            [
              59.392731,
              18.047947
            ],
            [
              59.392817,
              18.048069
            ],
            [
              59.39304,
              18.048398
            ],
            [
              59.393088,
              18.04848
            ],
            [
              59.393278,
              18.048814
            ],
            [
              59.393522,
              18.049264
            ],
            [
              59.393846,
              18.049954
            ],
            [
              59.393887,
              18.050049
            ],
            [
              59.394154,
              18.050715
            ],
            [
              59.394208,
              18.05087
            ],
            [
              59.394497,
              18.051747
            ],
            [
              59.394544,
              18.051909
            ],
            [
              59.394755,
              18.052653
            ],
            [
              59.39499,
              18.053527
            ],
            [
              59.395274,
              18.054701
            ],
            [
              59.395519,
              18.055576
            ],
            [
              59.395541,
              18.055647
            ],
            [
              59.395573,
              18.055733
            ],
            [
              59.395719,
              18.056124
            ],
            [
              59.395752,
              18.056207
            ],
            [
              59.395795,
              18.056301
            ],
            [
              59.395948,
              18.056621
            ],
            [
              59.395993,
              18.056712
            ],
            [
              59.396024,
              18.056768
            ],
            [
              59.396178,
              18.057026
            ],
            [
              59.396212,
              18.057075
            ],
            [
              59.396266,
              18.057142
            ],
            [
              59.39661,
              18.05756
            ],
            [
              59.397,
              18.057973
            ],
            [
              59.397038,
              18.058008
            ],
            [
              59.397068,
              18.058032
            ],
            [
              59.397709,
              18.058496
            ],
            [
              59.3979,
              18.058538
            ],
            [
              59.397963,
              18.058555
            ],
            [
              59.398515,
              18.058774
            ],
            [
              59.398578,
              18.058795
            ],
            [
              59.39905,
              18.058897
            ],
            [
              59.39905,
              18.058951
            ],
            [
              59.399256,
              18.058991
            ],
            [
              59.400742,
              18.059221
            ],
            [
              59.401899,
              18.059356
            ],
            [
              59.403262,
              18.059482
            ],
            [
              59.403923,
              18.059698
            ],
            [
              59.404431,
              18.059914
            ],
            [
              59.405355,
              18.060486
            ],
            [
              59.405585,
              18.06057
            ],
            [
              59.406292,
              18.06083
            ],
            [
              59.406862,
              18.060778
            ],
            [
              59.408775,
              18.059807
            ],
            [
              59.409923,
              18.059177
            ],
            [
              59.412893,
              18.057672
            ],
            [
              59.413371,
              18.057429
            ],
            [
              59.414074,
              18.056992
            ],
            [
              59.414383,
              18.056679
            ],
            [
              59.414698,
              18.056195
            ],
            [
              59.415005,
              18.055596
            ],
            [
              59.415388,
              18.054673
            ],
            [
              59.415972,
              18.053422
            ],
            [
              59.416373,
              18.052807
            ],
            [
              59.416832,
              18.052241
            ],
            [
              59.41734,
              18.051728
            ],
            [
              59.419029,
              18.050202
            ],
            [
              59.419526,
              18.049941
            ],
            [
              59.42,
              18.049792
            ],
            [
              59.420687,
              18.049822
            ],
            [
              59.421287,
              18.049968
            ],
            [
              59.421996,
              18.050213
            ],
            [
              59.423688,
              18.051235
            ],
            [
              59.424447,
              18.051235
            ],
            [
              59.425219,
              18.051221
            ],
            [
              59.425894,
              18.051237
            ],
            [
              59.425975,
              18.051239
            ],
            [
              59.426573,
              18.051043
            ],
            [
              59.429686,
              18.051108
            ],
            [
              59.430157,
              18.051235
            ],
            [
              59.430588,
              18.051387
            ],
            [
              59.430924,
              18.051575
            ],
            [
              59.431227,
              18.051784
            ],
            [
              59.43149,
              18.052004
            ],
            [
              59.432089,
              18.05257
            ],
            [
              59.432696,
              18.053237
            ],
            [
              59.432853,
              18.05346
            ],
            [
              59.433005,
              18.053715
            ],
            [
              59.4345,
              18.056329
            ],
            [
              59.435069,
              18.057197
            ],
            [
              59.435198,
              18.057416
            ],
            [
              59.435272,
              18.057542
            ],
            [
              59.435627,
              18.058066
            ],
            [
              59.436154,
              18.058596
            ],
            [
              59.436817,
              18.059265
            ],
            [
              59.437021,
              18.059497
            ],
            [
              59.43739,
              18.05997
            ],
            [
              59.437752,
              18.060508
            ],
            [
              59.438172,
              18.061259
            ],
            [
              59.440956,
              18.067235
            ],
            [
              59.441976,
              18.069362
            ],
            [
              59.442471,
              18.070576
            ],
            [
              59.443483,
              18.072734
            ],
            [
              59.444262,
              18.0744
            ],
            [
              59.44438,
              18.074691
            ],
            [
              59.44438,
              18.07469
            ],
            [
              59.444519,
              18.075031
            ],
            [
              59.444556,
              18.075132
            ],
            [
              59.444741,
              18.075672
            ],
            [
              59.444774,
              18.07578
            ],
            [
              59.445716,
              18.079265
            ],
            [
              59.446307,
              18.081624
            ],
            [
              59.446383,
              18.081935
            ],
            [
              59.446472,
              18.082338
            ],
            [
              59.446557,
              18.082709
            ],
            [
              59.446706,
              18.083406
            ],
            [
              59.446731,
              18.083529
            ],
            [
              59.446746,
              18.083608
            ],
            [
              59.446785,
              18.083847
            ],
            [
              59.446831,
              18.084192
            ],
            [
              59.44689,
              18.084704
            ],
            [
              59.446934,
              18.085136
            ],
            [
              59.446944,
              18.085243
            ],
            [
              59.446973,
              18.085602
            ],
            [
              59.447094,
              18.087033
            ],
            [
              59.447291,
              18.089118
            ],
            [
              59.447376,
              18.089998
            ],
            [
              59.447486,
              18.091157
            ],
            [
              59.447739,
              18.093984
            ],
            [
              59.447786,
              18.09454
            ],
            [
              59.447844,
              18.095138
            ],
            [
              59.447986,
              18.0968
            ],
            [
              59.448144,
              18.09871
            ],
            [
              59.448164,
              18.098903
            ],
            [
              59.448204,
              18.099351
            ],
            [
              59.448244,
              18.09978
            ],
            [
              59.448277,
              18.100105
            ],
            [
              59.448287,
              18.100206
            ],
            [
              59.448348,
              18.100711
            ],
            [
              59.448375,
              18.100908
            ],
            [
              59.448435,
              18.101299
            ],
            [
              59.448561,
              18.10198
            ],
            [
              59.448588,
              18.102113
            ],
            [
              59.448628,
              18.102281
            ],
            [
              59.448695,
              18.102539
            ],
            [
              59.448731,
              18.102666
            ],
            [
              59.448793,
              18.102878
            ],
            [
              59.448821,
              18.102965
            ],
            [
              59.448839,
              18.103017
            ],
            [
              59.448946,
              18.103308
            ],
            [
              59.449062,
              18.103631
            ],
            [
              59.449268,
              18.104143
            ],
            [
              59.449476,
              18.104656
            ],
            [
              59.449722,
              18.105214
            ],
            [
              59.449776,
              18.105317
            ],
            [
              59.45015,
              18.105984
            ],
            [
              59.450288,
              18.106222
            ],
            [
              59.450337,
              18.106303
            ],
            [
              59.450658,
              18.106753
            ],
            [
              59.451112,
              18.107436
            ],
            [
              59.451406,
              18.107944
            ],
            [
              59.451791,
              18.108556
            ],
            [
              59.452221,
              18.109294
            ],
            [
              59.452323,
              18.109486
            ],
            [
              59.452401,
              18.109641
            ],
            [
              59.452428,
              18.1097
            ],
            [
              59.452461,
              18.109779
            ],
            [
              59.452537,
              18.109975
            ],
            [
              59.45258,
              18.110092
            ],
            [
              59.452701,
              18.110477
            ],
            [
              59.452786,
              18.110779
            ],
            [
              59.4528,
              18.110834
            ],
            [
              59.452815,
              18.110905
            ],
            [
              59.452877,
              18.111233
            ],
            [
              59.452902,
              18.111394
            ],
            [
              59.452928,
              18.111571
            ],
            [
              59.452952,
              18.111745
            ],
            [
              59.452962,
              18.111846
            ],
            [
              59.452981,
              18.112135
            ],
            [
              59.452994,
              18.112432
            ],
            [
              59.452998,
              18.112619
            ],
            [
              59.452996,
              18.11286
            ],
            [
              59.452988,
              18.113108
            ],
            [
              59.45298,
              18.113232
            ],
            [
              59.452939,
              18.113677
            ],
            [
              59.452922,
              18.113814
            ],
            [
              59.452875,
              18.11409
            ],
            [
              59.452805,
              18.114442
            ],
            [
              59.452709,
              18.114872
            ],
            [
              59.45257,
              18.11548
            ],
            [
              59.452376,
              18.116375
            ],
            [
              59.452352,
              18.11649
            ],
            [
              59.452252,
              18.117013
            ],
            [
              59.452133,
              18.117728
            ],
            [
              59.452111,
              18.117868
            ],
            [
              59.452043,
              18.118354
            ],
            [
              59.451945,
              18.119091
            ],
            [
              59.451773,
              18.12029
            ],
            [
              59.451685,
              18.120881
            ],
            [
              59.45162,
              18.121352
            ],
            [
              59.451523,
              18.121962
            ],
            [
              59.451364,
              18.122982
            ],
            [
              59.451304,
              18.123337
            ],
            [
              59.45126,
              18.123573
            ],
            [
              59.451221,
              18.123768
            ],
            [
              59.451102,
              18.124337
            ],
            [
              59.451069,
              18.124488
            ],
            [
              59.45099,
              18.124833
            ],
            [
              59.450896,
              18.125213
            ],
            [
              59.45067,
              18.126074
            ],
            [
              59.450586,
              18.126368
            ],
            [
              59.450447,
              18.126839
            ],
            [
              59.450246,
              18.127567
            ],
            [
              59.450095,
              18.128088
            ],
            [
              59.450065,
              18.128197
            ],
            [
              59.450036,
              18.128323
            ],
            [
              59.450009,
              18.128451
            ],
            [
              59.449908,
              18.128976
            ],
            [
              59.449852,
              18.129292
            ],
            [
              59.449835,
              18.129412
            ],
            [
              59.449818,
              18.129554
            ],
            [
              59.449801,
              18.129733
            ],
            [
              59.449793,
              18.129852
            ],
            [
              59.44979,
              18.13
            ],
            [
              59.44979,
              18.130147
            ],
            [
              59.449796,
              18.130407
            ],
            [
              59.449804,
              18.130559
            ],
            [
              59.449814,
              18.130698
            ],
            [
              59.44986,
              18.131237
            ],
            [
              59.449878,
              18.131399
            ],
            [
              59.449886,
              18.131457
            ],
            [
              59.449902,
              18.131547
            ],
            [
              59.450026,
              18.132161
            ],
            [
              59.450072,
              18.132338
            ],
            [
              59.450111,
              18.132477
            ],
            [
              59.450179,
              18.132683
            ],
            [
              59.450221,
              18.132801
            ],
            [
              59.450259,
              18.1329
            ],
            [
              59.450293,
              18.132979
            ],
            [
              59.450465,
              18.133348
            ],
            [
              59.450519,
              18.133448
            ],
            [
              59.450657,
              18.133679
            ],
            [
              59.450708,
              18.133759
            ],
            [
              59.450912,
              18.13402
            ],
            [
              59.45103,
              18.134152
            ],
            [
              59.451085,
              18.13421
            ],
            [
              59.452101,
              18.1351
            ],
            [
              59.453436,
              18.136211
            ],
            [
              59.45358,
              18.136324
            ],
            [
              59.454218,
              18.136877
            ],
            [
              59.454887,
              18.137444
            ],
            [
              59.455072,
              18.137619
            ],
            [
              59.455412,
              18.137915
            ],
            [
              59.457123,
              18.139547
            ],
            [
              59.45769,
              18.140161
            ],
            [
              59.458179,
              18.140801
            ],
            [
              59.4588,
              18.14157
            ],
            [
              59.458823,
              18.141612
            ],
            [
              59.459633,
              18.142703
            ],
            [
              59.460273,
              18.143721
            ],
            [
              59.461317,
              18.145282
            ],
            [
              59.461747,
              18.146031
            ],
            [
              59.462401,
              18.147983
            ],
            [
              59.463216,
              18.152164
            ],
            [
              59.463522,
              18.154022
            ],
            [
              59.464183,
              18.157238
            ],
            [
              59.465068,
              18.160475
            ],
            [
              59.465479,
              18.161938
            ],
            [
              59.465602,
              18.162231
            ],
            [
              59.46575,
              18.16256
            ],
            [
              59.465787,
              18.162635
            ],
            [
              59.465912,
              18.162862
            ],
            [
              59.466087,
              18.163165
            ],
            [
              59.466297,
              18.16351
            ],
            [
              59.466616,
              18.163957
            ],
            [
              59.466882,
              18.164335
            ],
            [
              59.466941,
              18.164423
            ],
            [
              59.467225,
              18.164919
            ],
            [
              59.467284,
              18.165041
            ],
            [
              59.467443,
              18.165385
            ],
            [
              59.467499,
              18.165511
            ],
            [
              59.467671,
              18.165922
            ],
            [
              59.467698,
              18.165993
            ],
            [
              59.467726,
              18.166081
            ],
            [
              59.467795,
              18.166319
            ],
            [
              59.467917,
              18.166758
            ],
            [
              59.468014,
              18.167127
            ],
            [
              59.468044,
              18.16726
            ],
            [
              59.468089,
              18.167472
            ],
            [
              59.468103,
              18.167549
            ],
            [
              59.468124,
              18.167684
            ],
            [
              59.468143,
              18.16782
            ],
            [
              59.468184,
              18.168147
            ],
            [
              59.468222,
              18.168493
            ],
            [
              59.468239,
              18.168675
            ],
            [
              59.468273,
              18.169097
            ],
            [
              59.468297,
              18.169499
            ],
            [
              59.468307,
              18.169739
            ],
            [
              59.468312,
              18.169878
            ],
            [
              59.468315,
              18.17004
            ],
            [
              59.468316,
              18.170162
            ],
            [
              59.468316,
              18.170286
            ],
            [
              59.468312,
              18.170451
            ],
            [
              59.468302,
              18.170597
            ],
            [
              59.46828,
              18.170866
            ],
            [
              59.468238,
              18.171333
            ],
            [
              59.468189,
              18.171768
            ],
            [
              59.468136,
              18.172225
            ],
            [
              59.468064,
              18.172725
            ],
            [
              59.468004,
              18.173105
            ],
            [
              59.467909,
              18.173676
            ],
            [
              59.467799,
              18.174265
            ],
            [
              59.467693,
              18.174786
            ],
            [
              59.467577,
              18.175321
            ],
            [
              59.467532,
              18.17551
            ],
            [
              59.467283,
              18.176457
            ],
            [
              59.467242,
              18.176604
            ],
            [
              59.466751,
              18.178202
            ],
            [
              59.466342,
              18.179555
            ],
            [
              59.466094,
              18.180451
            ],
            [
              59.466059,
              18.1806
            ],
            [
              59.465994,
              18.180901
            ],
            [
              59.465859,
              18.181564
            ],
            [
              59.465727,
              18.182285
            ],
            [
              59.465665,
              18.182672
            ],
            [
              59.465621,
              18.182971
            ],
            [
              59.4656,
              18.183131
            ],
            [
              59.465565,
              18.183427
            ],
            [
              59.46553,
              18.183762
            ],
            [
              59.465459,
              18.184572
            ],
            [
              59.465444,
              18.184806
            ],
            [
              59.46541,
              18.185302
            ],
            [
              59.46539,
              18.185709
            ],
            [
              59.465385,
              18.185855
            ],
            [
              59.465367,
              18.186534
            ],
            [
              59.465368,
              18.186744
            ],
            [
              59.465371,
              18.187033
            ],
            [
              59.465377,
              18.187339
            ],
            [
              59.465387,
              18.187677
            ],
            [
              59.465432,
              18.188531
            ],
            [
              59.465464,
              18.188955
            ],
            [
              59.465494,
              18.189278
            ],
            [
              59.465505,
              18.18938
            ],
            [
              59.465571,
              18.189949
            ],
            [
              59.465637,
              18.190418
            ],
            [
              59.465673,
              18.190645
            ],
            [
              59.465728,
              18.191029
            ],
            [
              59.465762,
              18.191228
            ],
            [
              59.4659,
              18.191974
            ],
            [
              59.465975,
              18.192339
            ],
            [
              59.466043,
              18.192635
            ],
            [
              59.466097,
              18.192858
            ],
            [
              59.466158,
              18.1931
            ],
            [
              59.466232,
              18.193379
            ],
            [
              59.466252,
              18.193453
            ],
            [
              59.46636,
              18.193819
            ],
            [
              59.466493,
              18.194283
            ],
            [
              59.466689,
              18.194939
            ],
            [
              59.46682,
              18.195362
            ],
            [
              59.466959,
              18.195827
            ],
            [
              59.467472,
              18.197512
            ],
            [
              59.467523,
              18.197675
            ],
            [
              59.467712,
              18.198264
            ],
            [
              59.467907,
              18.198911
            ],
            [
              59.467951,
              18.199079
            ],
            [
              59.468258,
              18.20029
            ],
            [
              59.4684,
              18.200933
            ],
            [
              59.468431,
              18.201082
            ],
            [
              59.468492,
              18.201394
            ],
            [
              59.468631,
              18.20214
            ],
            [
              59.468677,
              18.202426
            ],
            [
              59.468762,
              18.203016
            ],
            [
              59.468804,
              18.20332
            ],
            [
              59.468854,
              18.203717
            ],
            [
              59.468904,
              18.20414
            ],
            [
              59.468957,
              18.204536
            ],
            [
              59.469001,
              18.204843
            ],
            [
              59.469111,
              18.205804
            ],
            [
              59.469206,
              18.20656
            ],
            [
              59.469313,
              18.207471
            ],
            [
              59.469347,
              18.207775
            ],
            [
              59.469359,
              18.207897
            ],
            [
              59.469411,
              18.208472
            ],
            [
              59.46945,
              18.20893
            ],
            [
              59.469482,
              18.209373
            ],
            [
              59.469509,
              18.209914
            ],
            [
              59.469532,
              18.210615
            ],
            [
              59.469543,
              18.211945
            ],
            [
              59.469526,
              18.212486
            ],
            [
              59.469441,
              18.214147
            ],
            [
              59.469361,
              18.215391
            ],
            [
              59.469392,
              18.215397
            ],
            [
              59.469377,
              18.215568
            ],
            [
              59.469357,
              18.21577
            ],
            [
              59.469331,
              18.215987
            ],
            [
              59.469275,
              18.217747
            ],
            [
              59.469185,
              18.220115
            ],
            [
              59.469171,
              18.221082
            ],
            [
              59.469182,
              18.221807
            ],
            [
              59.469205,
              18.222654
            ],
            [
              59.469241,
              18.223234
            ],
            [
              59.469289,
              18.223839
            ],
            [
              59.469362,
              18.224395
            ],
            [
              59.469435,
              18.225024
            ],
            [
              59.469508,
              18.225411
            ],
            [
              59.469581,
              18.225968
            ],
            [
              59.469703,
              18.226645
            ],
            [
              59.469837,
              18.227178
            ],
            [
              59.470033,
              18.228074
            ],
            [
              59.470265,
              18.228776
            ],
            [
              59.470497,
              18.229648
            ],
            [
              59.470754,
              18.230278
            ],
            [
              59.471,
              18.230812
            ],
            [
              59.471118,
              18.23108
            ],
            [
              59.471183,
              18.231193
            ],
            [
              59.47126,
              18.231349
            ],
            [
              59.471247,
              18.231374
            ],
            [
              59.471299,
              18.231395
            ],
            [
              59.471404,
              18.231614
            ],
            [
              59.472425,
              18.233702
            ],
            [
              59.472531,
              18.233923
            ],
            [
              59.472753,
              18.234374
            ],
            [
              59.473232,
              18.235367
            ],
            [
              59.473369,
              18.23565
            ],
            [
              59.473577,
              18.23607
            ],
            [
              59.473977,
              18.236867
            ],
            [
              59.474082,
              18.237087
            ],
            [
              59.47445,
              18.237813
            ],
            [
              59.474571,
              18.238061
            ],
            [
              59.474668,
              18.238272
            ],
            [
              59.474791,
              18.238558
            ],
            [
              59.475026,
              18.239131
            ],
            [
              59.475062,
              18.239229
            ],
            [
              59.475249,
              18.23978
            ],
            [
              59.475482,
              18.240562
            ],
            [
              59.475507,
              18.240654
            ],
            [
              59.475551,
              18.240823
            ],
            [
              59.475635,
              18.241175
            ],
            [
              59.475693,
              18.241467
            ],
            [
              59.475719,
              18.241603
            ],
            [
              59.475797,
              18.242046
            ],
            [
              59.475873,
              18.242519
            ],
            [
              59.475934,
              18.24301
            ],
            [
              59.476004,
              18.243635
            ],
            [
              59.476044,
              18.24404
            ],
            [
              59.476095,
              18.24452
            ],
            [
              59.476134,
              18.244927
            ],
            [
              59.476169,
              18.245263
            ],
            [
              59.476228,
              18.245873
            ],
            [
              59.476296,
              18.246614
            ],
            [
              59.476329,
              18.246907
            ],
            [
              59.476357,
              18.247218
            ],
            [
              59.476433,
              18.247966
            ],
            [
              59.476492,
              18.248615
            ],
            [
              59.476568,
              18.249344
            ],
            [
              59.476683,
              18.250518
            ],
            [
              59.476737,
              18.251098
            ],
            [
              59.476799,
              18.251695
            ],
            [
              59.476921,
              18.252929
            ],
            [
              59.477004,
              18.253738
            ],
            [
              59.477015,
              18.253857
            ],
            [
              59.477033,
              18.254089
            ],
            [
              59.477045,
              18.254212
            ],
            [
              59.477119,
              18.254939
            ],
            [
              59.477184,
              18.255544
            ],
            [
              59.477235,
              18.255974
            ],
            [
              59.477251,
              18.256092
            ],
            [
              59.477273,
              18.256244
            ],
            [
              59.477323,
              18.25653
            ],
            [
              59.477376,
              18.256799
            ],
            [
              59.47745,
              18.257151
            ],
            [
              59.477486,
              18.257303
            ],
            [
              59.477598,
              18.257755
            ],
            [
              59.477617,
              18.257828
            ],
            [
              59.477739,
              18.258245
            ],
            [
              59.477829,
              18.258516
            ],
            [
              59.477943,
              18.258836
            ],
            [
              59.478005,
              18.258999
            ],
            [
              59.478108,
              18.259252
            ],
            [
              59.478202,
              18.259467
            ],
            [
              59.478315,
              18.25971
            ],
            [
              59.478366,
              18.259815
            ],
            [
              59.478403,
              18.259886
            ],
            [
              59.478833,
              18.260699
            ],
            [
              59.478985,
              18.261004
            ],
            [
              59.47912,
              18.261241
            ],
            [
              59.479265,
              18.261534
            ],
            [
              59.479486,
              18.261941
            ],
            [
              59.479889,
              18.262702
            ],
            [
              59.48015,
              18.263201
            ],
            [
              59.480248,
              18.263432
            ],
            [
              59.480341,
              18.263671
            ],
            [
              59.480429,
              18.263919
            ],
            [
              59.48051,
              18.264174
            ],
            [
              59.480586,
              18.264436
            ],
            [
              59.480655,
              18.264705
            ],
            [
              59.480718,
              18.26498
            ],
            [
              59.480775,
              18.26526
            ],
            [
              59.480825,
              18.265545
            ],
            [
              59.480869,
              18.265834
            ],
            [
              59.480905,
              18.266126
            ],
            [
              59.480935,
              18.266422
            ],
            [
              59.480941,
              18.266594
            ],
            [
              59.480941,
              18.266767
            ],
            [
              59.480938,
              18.266939
            ],
            [
              59.480923,
              18.267176
            ],
            [
              59.480895,
              18.267537
            ],
            [
              59.480789,
              18.269049
            ],
            [
              59.480773,
              18.269235
            ],
            [
              59.480697,
              18.270019
            ],
            [
              59.48066,
              18.270424
            ],
            [
              59.480588,
              18.270413
            ],
            [
              59.480436,
              18.273188
            ],
            [
              59.479988,
              18.288838
            ],
            [
              59.479969,
              18.290708
            ],
            [
              59.479713,
              18.293239
            ],
            [
              59.479485,
              18.295718
            ],
            [
              59.47913,
              18.298545
            ],
            [
              59.478979,
              18.29979
            ],
            [
              59.478973,
              18.299889
            ],
            [
              59.478605,
              18.301445
            ],
            [
              59.477714,
              18.302834
            ],
            [
              59.475676,
              18.306371
            ],
            [
              59.474379,
              18.30802
            ],
            [
              59.473967,
              18.308072
            ],
            [
              59.472618,
              18.308493
            ],
            [
              59.471987,
              18.308386
            ],
            [
              59.470442,
              18.307773
            ],
            [
              59.468703,
              18.307419
            ],
            [
              59.468737,
              18.307433
            ],
            [
              59.468252,
              18.307439
            ],
            [
              59.467356,
              18.307116
            ],
            [
              59.466585,
              18.306868
            ],
            [
              59.465827,
              18.306578
            ],
            [
              59.465511,
              18.306639
            ],
            [
              59.465221,
              18.306836
            ],
            [
              59.464916,
              18.30714
            ],
            [
              59.464561,
              18.307537
            ],
            [
              59.463055,
              18.309176
            ],
            [
              59.462208,
              18.310067
            ],
            [
              59.461859,
              18.310457
            ]
          ]
        }
      ],
      "daysOfService": {
        "rvb": "0000000000000000000000004F9F000039F3E7CF3E7CF9F327CF9F3E000007CF"
      }
    }
  ]
}
````