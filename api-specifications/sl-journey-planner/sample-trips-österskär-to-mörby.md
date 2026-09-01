Request:
https://journeyplanner.integration.sl.se/v2/trips?type_origin=any&name_origin=9091001001009660&type_destination=any&name_destination=9091001001009638&date=2026-09-01&time=18:41&calc_number_of_trips=3

Response
```json
{
  "systemMessages": [
    
  ],
  "journeys": [
    {
      "tripDuration": 1740,
      "tripRtDuration": 1710,
      "rating": 0,
      "isAdditional": false,
      "interchanges": 0,
      "legs": [
        {
          "infos": [
            
          ],
          "duration": 1710,
          "origin": {
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
            "departureTimeBaseTimetable": "2026-09-01T18:33:00Z",
            "departureTimePlanned": "2026-09-01T18:33:00Z",
            "departureTimeEstimated": "2026-09-01T18:33:12Z",
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
          "destination": {
            "isGlobalId": true,
            "id": "9025001000007142",
            "name": "Mörby, Danderyd",
            "disassembledName": "2",
            "type": "platform",
            "coord": [
              59.392339,
              18.047451
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
            "arrivalTimeBaseTimetable": "2026-09-01T19:02:00Z",
            "arrivalTimePlanned": "2026-09-01T19:02:00Z",
            "arrivalTimeEstimated": "2026-09-01T19:01:42Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "2",
              "platform": "1",
              "stoppingPointPlanned": "2",
              "platformName": "2",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "transportation": {
            "id": "tfs:03028:A:H:y01",
            "name": "Spårvagn Roslagsbanan 28S",
            "number": "Roslagsbanan 28S",
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
              "id": "18006601",
              "name": "Stockholms östra",
              "type": "stop"
            },
            "properties": {
              "tripCode": 10,
              "timetablePeriod": "Current",
              "lineDisplay": "LINE",
              "globalId": "9011001002800000",
              "RealtimeTripId": "9015001002806975",
              "shortTrain": true,
              "AVMSTripID": "9015001002806975"
            },
            "isSamtrafik": false,
            "disassembledName": "28S"
          },
          "stopSequence": [
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
              "departureTimePlanned": "2026-09-01T18:33:00Z",
              "departureTimeEstimated": "2026-09-01T18:33:12Z"
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
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:34:00Z",
              "departureTimeEstimated": "2026-09-01T18:35:00Z",
              "arrivalTimePlanned": "2026-09-01T18:34:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:33:48Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007073",
              "name": "Åkersberga, Österåker",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.478994,
                18.299886
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
                "area": "3",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T18:37:00Z",
              "departureTimeEstimated": "2026-09-01T18:37:24Z",
              "arrivalTimePlanned": "2026-09-01T18:37:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:36:18Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007036",
              "name": "Arninge, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.458809,
                18.141495
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T18:46:00Z",
              "departureTimeEstimated": "2026-09-01T18:46:30Z",
              "arrivalTimePlanned": "2026-09-01T18:46:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:45:18Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007032",
              "name": "Hägernäs, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.450884,
                18.125182
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T18:48:00Z",
              "departureTimeEstimated": "2026-09-01T18:48:48Z",
              "arrivalTimePlanned": "2026-09-01T18:48:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:47:42Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007021",
              "name": "Viggbyholm, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.449226,
                18.10417
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
                "area": "1",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T18:51:00Z",
              "departureTimeEstimated": "2026-09-01T18:51:12Z",
              "arrivalTimePlanned": "2026-09-01T18:51:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:50:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007012",
              "name": "Galoppfältet, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.446856,
                18.08518
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T18:52:00Z",
              "departureTimeEstimated": "2026-09-01T18:52:18Z",
              "arrivalTimePlanned": "2026-09-01T18:52:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:52:06Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007002",
              "name": "Täby centrum, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.444368,
                18.07466
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T18:54:00Z",
              "departureTimeEstimated": "2026-09-01T18:54:12Z",
              "arrivalTimePlanned": "2026-09-01T18:54:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:53:12Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007194",
              "name": "Roslags Näsby, Täby",
              "disassembledName": "4",
              "type": "platform",
              "coord": [
                59.435192,
                18.057404
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
                "area": "4",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "4",
                "platformName": "4"
              },
              "departureTimePlanned": "2026-09-01T18:57:00Z",
              "departureTimeEstimated": "2026-09-01T18:57:00Z",
              "arrivalTimePlanned": "2026-09-01T18:57:00Z",
              "arrivalTimeEstimated": "2026-09-01T18:55:42Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007142",
              "name": "Mörby, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.392339,
                18.047451
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "arrivalTimePlanned": "2026-09-01T19:02:00Z",
              "arrivalTimeEstimated": "2026-09-01T19:01:42Z"
            }
          ],
          "properties": {
            "tripId": "9015001002806975"
          },
          "coords": [
            [
              59.461364,
              18.311007
            ],
            [
              59.463482,
              18.308532
            ],
            [
              59.464733,
              18.307167
            ],
            [
              59.465201,
              18.306814
            ],
            [
              59.465639,
              18.306618
            ],
            [
              59.466565,
              18.306895
            ],
            [
              59.467732,
              18.307248
            ],
            [
              59.468755,
              18.307401
            ],
            [
              59.468737,
              18.307313
            ],
            [
              59.46884,
              18.307319
            ],
            [
              59.469078,
              18.307347
            ],
            [
              59.469289,
              18.307388
            ],
            [
              59.469481,
              18.307434
            ],
            [
              59.469803,
              18.307494
            ],
            [
              59.469855,
              18.307513
            ],
            [
              59.470073,
              18.307611
            ],
            [
              59.47081,
              18.3079
            ],
            [
              59.471405,
              18.308158
            ],
            [
              59.471847,
              18.308331
            ],
            [
              59.471908,
              18.308349
            ],
            [
              59.471978,
              18.308364
            ],
            [
              59.472309,
              18.308401
            ],
            [
              59.472371,
              18.308402
            ],
            [
              59.472548,
              18.308397
            ],
            [
              59.47277,
              18.308398
            ],
            [
              59.472812,
              18.308396
            ],
            [
              59.473316,
              18.308294
            ],
            [
              59.473495,
              18.308265
            ],
            [
              59.473569,
              18.30825
            ],
            [
              59.473771,
              18.308192
            ],
            [
              59.473953,
              18.308127
            ],
            [
              59.474014,
              18.308102
            ],
            [
              59.474185,
              18.308024
            ],
            [
              59.474236,
              18.307998
            ],
            [
              59.474442,
              18.307877
            ],
            [
              59.474523,
              18.307825
            ],
            [
              59.47462,
              18.307752
            ],
            [
              59.474667,
              18.307712
            ],
            [
              59.474846,
              18.307544
            ],
            [
              59.47492,
              18.307463
            ],
            [
              59.475132,
              18.307222
            ],
            [
              59.475176,
              18.307162
            ],
            [
              59.475366,
              18.306859
            ],
            [
              59.475616,
              18.306479
            ],
            [
              59.475688,
              18.306357
            ],
            [
              59.476021,
              18.305772
            ],
            [
              59.47646,
              18.305029
            ],
            [
              59.476857,
              18.304333
            ],
            [
              59.47732,
              18.303547
            ],
            [
              59.47736,
              18.303477
            ],
            [
              59.477401,
              18.3034
            ],
            [
              59.477448,
              18.303316
            ],
            [
              59.478413,
              18.30167
            ],
            [
              59.478459,
              18.301583
            ],
            [
              59.478546,
              18.301399
            ],
            [
              59.478632,
              18.301186
            ],
            [
              59.478668,
              18.301084
            ],
            [
              59.478791,
              18.3007
            ],
            [
              59.47888,
              18.300404
            ],
            [
              59.478905,
              18.300311
            ],
            [
              59.478945,
              18.30014
            ],
            [
              59.478991,
              18.299909
            ],
            [
              59.479018,
              18.299751
            ],
            [
              59.479061,
              18.299473
            ],
            [
              59.479119,
              18.298998
            ],
            [
              59.479299,
              18.297291
            ],
            [
              59.479392,
              18.296382
            ],
            [
              59.47951,
              18.295405
            ],
            [
              59.479578,
              18.294726
            ],
            [
              59.479646,
              18.294089
            ],
            [
              59.479736,
              18.293176
            ],
            [
              59.47976,
              18.29292
            ],
            [
              59.479838,
              18.292184
            ],
            [
              59.479882,
              18.291703
            ],
            [
              59.479934,
              18.291163
            ],
            [
              59.479987,
              18.290501
            ],
            [
              59.480023,
              18.289991
            ],
            [
              59.480035,
              18.289685
            ],
            [
              59.480047,
              18.289226
            ],
            [
              59.480061,
              18.288761
            ],
            [
              59.480202,
              18.281876
            ],
            [
              59.480249,
              18.27974
            ],
            [
              59.480258,
              18.279158
            ],
            [
              59.480271,
              18.278768
            ],
            [
              59.480276,
              18.278583
            ],
            [
              59.480337,
              18.275795
            ],
            [
              59.48036,
              18.274924
            ],
            [
              59.480368,
              18.274434
            ],
            [
              59.480372,
              18.274289
            ],
            [
              59.480392,
              18.273789
            ],
            [
              59.480399,
              18.273643
            ],
            [
              59.480434,
              18.273057
            ],
            [
              59.480451,
              18.272808
            ],
            [
              59.480487,
              18.272336
            ],
            [
              59.480592,
              18.271164
            ],
            [
              59.480626,
              18.27081
            ],
            [
              59.48066,
              18.270424
            ],
            [
              59.480697,
              18.270019
            ],
            [
              59.480773,
              18.269235
            ],
            [
              59.480789,
              18.269049
            ],
            [
              59.480895,
              18.267537
            ],
            [
              59.480923,
              18.267176
            ],
            [
              59.480942,
              18.266865
            ],
            [
              59.48095,
              18.266649
            ],
            [
              59.480951,
              18.266548
            ],
            [
              59.480947,
              18.266359
            ],
            [
              59.480934,
              18.265965
            ],
            [
              59.480928,
              18.265845
            ],
            [
              59.480915,
              18.265689
            ],
            [
              59.480888,
              18.26546
            ],
            [
              59.48085,
              18.265204
            ],
            [
              59.480837,
              18.265126
            ],
            [
              59.480783,
              18.264853
            ],
            [
              59.480766,
              18.264778
            ],
            [
              59.480734,
              18.264649
            ],
            [
              59.480695,
              18.264506
            ],
            [
              59.480621,
              18.264263
            ],
            [
              59.480531,
              18.264002
            ],
            [
              59.480507,
              18.263938
            ],
            [
              59.480482,
              18.263875
            ],
            [
              59.480391,
              18.263689
            ],
            [
              59.480291,
              18.263473
            ],
            [
              59.480223,
              18.263341
            ],
            [
              59.479889,
              18.262702
            ],
            [
              59.479486,
              18.261941
            ],
            [
              59.479265,
              18.261534
            ],
            [
              59.47912,
              18.261241
            ],
            [
              59.478985,
              18.261004
            ],
            [
              59.478802,
              18.260641
            ],
            [
              59.478703,
              18.260452
            ],
            [
              59.478545,
              18.260156
            ],
            [
              59.478366,
              18.259815
            ],
            [
              59.478315,
              18.25971
            ],
            [
              59.478202,
              18.259467
            ],
            [
              59.478089,
              18.259205
            ],
            [
              59.478005,
              18.258999
            ],
            [
              59.477961,
              18.258886
            ],
            [
              59.47787,
              18.258634
            ],
            [
              59.477829,
              18.258516
            ],
            [
              59.477739,
              18.258245
            ],
            [
              59.477617,
              18.257828
            ],
            [
              59.477598,
              18.257755
            ],
            [
              59.477486,
              18.257303
            ],
            [
              59.47745,
              18.257151
            ],
            [
              59.477376,
              18.256799
            ],
            [
              59.477323,
              18.25653
            ],
            [
              59.477273,
              18.256244
            ],
            [
              59.477251,
              18.256092
            ],
            [
              59.477235,
              18.255974
            ],
            [
              59.477184,
              18.255544
            ],
            [
              59.477119,
              18.254939
            ],
            [
              59.477045,
              18.254212
            ],
            [
              59.477033,
              18.254089
            ],
            [
              59.477015,
              18.253857
            ],
            [
              59.477004,
              18.253738
            ],
            [
              59.476921,
              18.252929
            ],
            [
              59.476799,
              18.251695
            ],
            [
              59.476737,
              18.251098
            ],
            [
              59.476683,
              18.250518
            ],
            [
              59.476568,
              18.249344
            ],
            [
              59.476492,
              18.248615
            ],
            [
              59.476433,
              18.247966
            ],
            [
              59.476357,
              18.247218
            ],
            [
              59.476329,
              18.246907
            ],
            [
              59.476296,
              18.246614
            ],
            [
              59.476228,
              18.245873
            ],
            [
              59.476169,
              18.245263
            ],
            [
              59.476134,
              18.244927
            ],
            [
              59.476095,
              18.24452
            ],
            [
              59.476044,
              18.24404
            ],
            [
              59.476004,
              18.243635
            ],
            [
              59.475934,
              18.24301
            ],
            [
              59.475873,
              18.242519
            ],
            [
              59.475797,
              18.242046
            ],
            [
              59.475719,
              18.241603
            ],
            [
              59.475693,
              18.241467
            ],
            [
              59.475635,
              18.241175
            ],
            [
              59.475551,
              18.240823
            ],
            [
              59.475507,
              18.240654
            ],
            [
              59.475482,
              18.240562
            ],
            [
              59.475249,
              18.23978
            ],
            [
              59.475062,
              18.239229
            ],
            [
              59.475026,
              18.239131
            ],
            [
              59.474791,
              18.238558
            ],
            [
              59.474668,
              18.238272
            ],
            [
              59.474571,
              18.238061
            ],
            [
              59.47445,
              18.237813
            ],
            [
              59.474082,
              18.237087
            ],
            [
              59.473977,
              18.236867
            ],
            [
              59.473577,
              18.23607
            ],
            [
              59.473369,
              18.23565
            ],
            [
              59.473238,
              18.23538
            ],
            [
              59.472753,
              18.234374
            ],
            [
              59.472531,
              18.233923
            ],
            [
              59.472425,
              18.233702
            ],
            [
              59.471404,
              18.231614
            ],
            [
              59.471299,
              18.231395
            ],
            [
              59.471247,
              18.231374
            ],
            [
              59.47126,
              18.231349
            ],
            [
              59.471183,
              18.231193
            ],
            [
              59.471118,
              18.23108
            ],
            [
              59.471,
              18.230812
            ],
            [
              59.470754,
              18.230278
            ],
            [
              59.470497,
              18.229648
            ],
            [
              59.470265,
              18.228776
            ],
            [
              59.470033,
              18.228074
            ],
            [
              59.469837,
              18.227178
            ],
            [
              59.469703,
              18.226645
            ],
            [
              59.469581,
              18.225968
            ],
            [
              59.469508,
              18.225411
            ],
            [
              59.469435,
              18.225024
            ],
            [
              59.469362,
              18.224395
            ],
            [
              59.469289,
              18.223839
            ],
            [
              59.469241,
              18.223234
            ],
            [
              59.469205,
              18.222654
            ],
            [
              59.469182,
              18.221807
            ],
            [
              59.469171,
              18.221082
            ],
            [
              59.469185,
              18.220115
            ],
            [
              59.469275,
              18.217747
            ],
            [
              59.469331,
              18.215987
            ],
            [
              59.469357,
              18.21577
            ],
            [
              59.469377,
              18.215568
            ],
            [
              59.469392,
              18.215397
            ],
            [
              59.469361,
              18.215391
            ],
            [
              59.469441,
              18.214147
            ],
            [
              59.469526,
              18.212486
            ],
            [
              59.469543,
              18.211945
            ],
            [
              59.469532,
              18.210615
            ],
            [
              59.469509,
              18.209914
            ],
            [
              59.469482,
              18.209373
            ],
            [
              59.46945,
              18.20893
            ],
            [
              59.469411,
              18.208472
            ],
            [
              59.469359,
              18.207897
            ],
            [
              59.469347,
              18.207775
            ],
            [
              59.469313,
              18.207471
            ],
            [
              59.469206,
              18.20656
            ],
            [
              59.469111,
              18.205804
            ],
            [
              59.469001,
              18.204843
            ],
            [
              59.468957,
              18.204536
            ],
            [
              59.468904,
              18.20414
            ],
            [
              59.468854,
              18.203717
            ],
            [
              59.468804,
              18.20332
            ],
            [
              59.468762,
              18.203016
            ],
            [
              59.468677,
              18.202426
            ],
            [
              59.468631,
              18.20214
            ],
            [
              59.468492,
              18.201394
            ],
            [
              59.468431,
              18.201082
            ],
            [
              59.4684,
              18.200933
            ],
            [
              59.468258,
              18.20029
            ],
            [
              59.467951,
              18.199079
            ],
            [
              59.467907,
              18.198911
            ],
            [
              59.467712,
              18.198264
            ],
            [
              59.467523,
              18.197675
            ],
            [
              59.467472,
              18.197512
            ],
            [
              59.466959,
              18.195827
            ],
            [
              59.46682,
              18.195362
            ],
            [
              59.466689,
              18.194939
            ],
            [
              59.466493,
              18.194283
            ],
            [
              59.46636,
              18.193819
            ],
            [
              59.466252,
              18.193453
            ],
            [
              59.466232,
              18.193379
            ],
            [
              59.466158,
              18.1931
            ],
            [
              59.466097,
              18.192858
            ],
            [
              59.466043,
              18.192635
            ],
            [
              59.465975,
              18.192339
            ],
            [
              59.4659,
              18.191974
            ],
            [
              59.465762,
              18.191228
            ],
            [
              59.465728,
              18.191029
            ],
            [
              59.465673,
              18.190645
            ],
            [
              59.465637,
              18.190418
            ],
            [
              59.465571,
              18.189949
            ],
            [
              59.465505,
              18.18938
            ],
            [
              59.465494,
              18.189278
            ],
            [
              59.465464,
              18.188955
            ],
            [
              59.465432,
              18.188531
            ],
            [
              59.465387,
              18.187677
            ],
            [
              59.465377,
              18.187339
            ],
            [
              59.465371,
              18.187033
            ],
            [
              59.465368,
              18.186744
            ],
            [
              59.465367,
              18.186534
            ],
            [
              59.465385,
              18.185873
            ],
            [
              59.465349,
              18.185926
            ],
            [
              59.465534,
              18.183609
            ],
            [
              59.465842,
              18.181493
            ],
            [
              59.466305,
              18.179644
            ],
            [
              59.466834,
              18.177674
            ],
            [
              59.467319,
              18.176206
            ],
            [
              59.467673,
              18.174851
            ],
            [
              59.467965,
              18.173427
            ],
            [
              59.468197,
              18.171809
            ],
            [
              59.468297,
              18.170304
            ],
            [
              59.46824,
              18.168721
            ],
            [
              59.468025,
              18.166997
            ],
            [
              59.467486,
              18.16537
            ],
            [
              59.466932,
              18.164371
            ],
            [
              59.466188,
              18.163292
            ],
            [
              59.465541,
              18.162159
            ],
            [
              59.465068,
              18.160475
            ],
            [
              59.464183,
              18.157238
            ],
            [
              59.463522,
              18.154022
            ],
            [
              59.463046,
              18.151139
            ],
            [
              59.462451,
              18.147866
            ],
            [
              59.461941,
              18.146368
            ],
            [
              59.460524,
              18.143902
            ],
            [
              59.458813,
              18.141599
            ],
            [
              59.4588,
              18.14157
            ],
            [
              59.458179,
              18.140801
            ],
            [
              59.45725,
              18.139585
            ],
            [
              59.456104,
              18.138517
            ],
            [
              59.454501,
              18.136987
            ],
            [
              59.453288,
              18.136038
            ],
            [
              59.45214,
              18.135053
            ],
            [
              59.451033,
              18.134156
            ],
            [
              59.450293,
              18.133041
            ],
            [
              59.44988,
              18.131623
            ],
            [
              59.449774,
              18.129814
            ],
            [
              59.450097,
              18.127878
            ],
            [
              59.450695,
              18.126051
            ],
            [
              59.450927,
              18.125235
            ],
            [
              59.450895,
              18.125213
            ],
            [
              59.45099,
              18.124833
            ],
            [
              59.451069,
              18.124488
            ],
            [
              59.451102,
              18.124337
            ],
            [
              59.451221,
              18.123768
            ],
            [
              59.45126,
              18.123573
            ],
            [
              59.451304,
              18.123337
            ],
            [
              59.451364,
              18.122982
            ],
            [
              59.451523,
              18.121962
            ],
            [
              59.45162,
              18.121352
            ],
            [
              59.451685,
              18.120881
            ],
            [
              59.451773,
              18.12029
            ],
            [
              59.451945,
              18.119091
            ],
            [
              59.452043,
              18.118354
            ],
            [
              59.452111,
              18.117868
            ],
            [
              59.452133,
              18.117728
            ],
            [
              59.452252,
              18.117013
            ],
            [
              59.452352,
              18.11649
            ],
            [
              59.452376,
              18.116375
            ],
            [
              59.45257,
              18.11548
            ],
            [
              59.452709,
              18.114872
            ],
            [
              59.452805,
              18.114442
            ],
            [
              59.452875,
              18.11409
            ],
            [
              59.452922,
              18.113814
            ],
            [
              59.452939,
              18.113677
            ],
            [
              59.45298,
              18.113232
            ],
            [
              59.452988,
              18.113108
            ],
            [
              59.452996,
              18.11286
            ],
            [
              59.452998,
              18.112619
            ],
            [
              59.452994,
              18.112432
            ],
            [
              59.452981,
              18.112135
            ],
            [
              59.452962,
              18.111846
            ],
            [
              59.452952,
              18.111745
            ],
            [
              59.452928,
              18.111571
            ],
            [
              59.452902,
              18.111394
            ],
            [
              59.452877,
              18.111233
            ],
            [
              59.452815,
              18.110905
            ],
            [
              59.4528,
              18.110834
            ],
            [
              59.452786,
              18.110779
            ],
            [
              59.452701,
              18.110477
            ],
            [
              59.45258,
              18.110092
            ],
            [
              59.452537,
              18.109975
            ],
            [
              59.452461,
              18.109779
            ],
            [
              59.452428,
              18.1097
            ],
            [
              59.452401,
              18.109641
            ],
            [
              59.452323,
              18.109486
            ],
            [
              59.452221,
              18.109294
            ],
            [
              59.451791,
              18.108556
            ],
            [
              59.451406,
              18.107944
            ],
            [
              59.451112,
              18.107436
            ],
            [
              59.450658,
              18.106753
            ],
            [
              59.450337,
              18.106303
            ],
            [
              59.450288,
              18.106222
            ],
            [
              59.45015,
              18.105984
            ],
            [
              59.449776,
              18.105317
            ],
            [
              59.449722,
              18.105214
            ],
            [
              59.449476,
              18.104656
            ],
            [
              59.449268,
              18.104143
            ],
            [
              59.449062,
              18.103631
            ],
            [
              59.448946,
              18.103308
            ],
            [
              59.448839,
              18.103017
            ],
            [
              59.448821,
              18.102965
            ],
            [
              59.448793,
              18.102878
            ],
            [
              59.448731,
              18.102666
            ],
            [
              59.448695,
              18.102539
            ],
            [
              59.448628,
              18.102281
            ],
            [
              59.448588,
              18.102113
            ],
            [
              59.448561,
              18.10198
            ],
            [
              59.448435,
              18.101299
            ],
            [
              59.448375,
              18.100908
            ],
            [
              59.448348,
              18.100711
            ],
            [
              59.448287,
              18.100206
            ],
            [
              59.448277,
              18.100105
            ],
            [
              59.448244,
              18.09978
            ],
            [
              59.448204,
              18.099351
            ],
            [
              59.448164,
              18.098903
            ],
            [
              59.448144,
              18.09871
            ],
            [
              59.447986,
              18.0968
            ],
            [
              59.447844,
              18.095138
            ],
            [
              59.447786,
              18.09454
            ],
            [
              59.447739,
              18.093984
            ],
            [
              59.447486,
              18.091157
            ],
            [
              59.447376,
              18.089998
            ],
            [
              59.447291,
              18.089118
            ],
            [
              59.447094,
              18.087033
            ],
            [
              59.446937,
              18.08517
            ],
            [
              59.44689,
              18.084704
            ],
            [
              59.446831,
              18.084192
            ],
            [
              59.446785,
              18.083847
            ],
            [
              59.446746,
              18.083608
            ],
            [
              59.446731,
              18.083529
            ],
            [
              59.446706,
              18.083406
            ],
            [
              59.446557,
              18.082709
            ],
            [
              59.446472,
              18.082338
            ],
            [
              59.446383,
              18.081935
            ],
            [
              59.446307,
              18.081624
            ],
            [
              59.445716,
              18.079265
            ],
            [
              59.444774,
              18.07578
            ],
            [
              59.444741,
              18.075672
            ],
            [
              59.444556,
              18.075132
            ],
            [
              59.444519,
              18.075031
            ],
            [
              59.44438,
              18.07469
            ],
            [
              59.444275,
              18.074433
            ],
            [
              59.444233,
              18.074339
            ],
            [
              59.443476,
              18.072719
            ],
            [
              59.442478,
              18.070591
            ],
            [
              59.441877,
              18.069292
            ],
            [
              59.438196,
              18.061471
            ],
            [
              59.438144,
              18.061364
            ],
            [
              59.438114,
              18.061305
            ],
            [
              59.437693,
              18.060528
            ],
            [
              59.437654,
              18.060458
            ],
            [
              59.437612,
              18.060395
            ],
            [
              59.437502,
              18.060242
            ],
            [
              59.437453,
              18.060169
            ],
            [
              59.437338,
              18.059996
            ],
            [
              59.437118,
              18.059658
            ],
            [
              59.437029,
              18.059526
            ],
            [
              59.436985,
              18.05947
            ],
            [
              59.436817,
              18.059265
            ],
            [
              59.436155,
              18.058595
            ],
            [
              59.435707,
              18.058075
            ],
            [
              59.435646,
              18.057993
            ],
            [
              59.435358,
              18.05758
            ],
            [
              59.435294,
              18.057472
            ],
            [
              59.435146,
              18.05721
            ],
            [
              59.435098,
              18.057129
            ],
            [
              59.435049,
              18.05705
            ],
            [
              59.434525,
              18.056229
            ],
            [
              59.43406,
              18.055432
            ],
            [
              59.433421,
              18.054343
            ],
            [
              59.433045,
              18.053729
            ],
            [
              59.432971,
              18.053611
            ],
            [
              59.432727,
              18.053234
            ],
            [
              59.432425,
              18.052809
            ],
            [
              59.43239,
              18.052763
            ],
            [
              59.432344,
              18.052708
            ],
            [
              59.432111,
              18.052447
            ],
            [
              59.431613,
              18.051959
            ],
            [
              59.431545,
              18.0519
            ],
            [
              59.43128,
              18.051692
            ],
            [
              59.431044,
              18.051507
            ],
            [
              59.430994,
              18.051471
            ],
            [
              59.430922,
              18.051433
            ],
            [
              59.430629,
              18.051297
            ],
            [
              59.430272,
              18.051163
            ],
            [
              59.430209,
              18.051142
            ],
            [
              59.430114,
              18.051124
            ],
            [
              59.429742,
              18.051074
            ],
            [
              59.429667,
              18.051067
            ],
            [
              59.428057,
              18.051076
            ],
            [
              59.427046,
              18.051123
            ],
            [
              59.426407,
              18.051175
            ],
            [
              59.425975,
              18.051238
            ],
            [
              59.425754,
              18.051253
            ],
            [
              59.425233,
              18.051288
            ],
            [
              59.424631,
              18.051316
            ],
            [
              59.424058,
              18.051254
            ],
            [
              59.423749,
              18.051202
            ],
            [
              59.423686,
              18.051188
            ],
            [
              59.423613,
              18.05116
            ],
            [
              59.423406,
              18.051072
            ],
            [
              59.423324,
              18.051032
            ],
            [
              59.422078,
              18.050263
            ],
            [
              59.421986,
              18.05021
            ],
            [
              59.4216,
              18.050046
            ],
            [
              59.421538,
              18.050024
            ],
            [
              59.420835,
              18.049813
            ],
            [
              59.420751,
              18.04979
            ],
            [
              59.420516,
              18.049749
            ],
            [
              59.420452,
              18.049741
            ],
            [
              59.420086,
              18.049736
            ],
            [
              59.420011,
              18.049738
            ],
            [
              59.419872,
              18.049764
            ],
            [
              59.41968,
              18.049817
            ],
            [
              59.419595,
              18.049843
            ],
            [
              59.419512,
              18.049875
            ],
            [
              59.419439,
              18.049906
            ],
            [
              59.419175,
              18.05004
            ],
            [
              59.419096,
              18.050091
            ],
            [
              59.418957,
              18.050186
            ],
            [
              59.418908,
              18.050224
            ],
            [
              59.418858,
              18.050266
            ],
            [
              59.418475,
              18.050596
            ],
            [
              59.418377,
              18.050684
            ],
            [
              59.417887,
              18.051142
            ],
            [
              59.417578,
              18.05146
            ],
            [
              59.417329,
              18.051691
            ],
            [
              59.416875,
              18.052141
            ],
            [
              59.416793,
              18.052236
            ],
            [
              59.41638,
              18.052746
            ],
            [
              59.416321,
              18.052834
            ],
            [
              59.416018,
              18.05332
            ],
            [
              59.415978,
              18.053388
            ],
            [
              59.415956,
              18.053433
            ],
            [
              59.415395,
              18.054658
            ],
            [
              59.415011,
              18.055579
            ],
            [
              59.41496,
              18.055684
            ],
            [
              59.414758,
              18.056079
            ],
            [
              59.414697,
              18.056193
            ],
            [
              59.414553,
              18.056426
            ],
            [
              59.414494,
              18.056513
            ],
            [
              59.414416,
              18.056622
            ],
            [
              59.414356,
              18.056695
            ],
            [
              59.414286,
              18.056773
            ],
            [
              59.414148,
              18.056906
            ],
            [
              59.414037,
              18.057004
            ],
            [
              59.414,
              18.057034
            ],
            [
              59.413971,
              18.057054
            ],
            [
              59.41387,
              18.05711
            ],
            [
              59.413774,
              18.057158
            ],
            [
              59.413361,
              18.057385
            ],
            [
              59.413061,
              18.057545
            ],
            [
              59.412803,
              18.057676
            ],
            [
              59.411807,
              18.058177
            ],
            [
              59.409913,
              18.059183
            ],
            [
              59.408757,
              18.059768
            ],
            [
              59.406992,
              18.060649
            ],
            [
              59.406849,
              18.060723
            ],
            [
              59.406797,
              18.060746
            ],
            [
              59.406723,
              18.060771
            ],
            [
              59.406607,
              18.060801
            ],
            [
              59.406459,
              18.060823
            ],
            [
              59.406386,
              18.060828
            ],
            [
              59.406185,
              18.060827
            ],
            [
              59.406089,
              18.060818
            ],
            [
              59.406048,
              18.06081
            ],
            [
              59.405946,
              18.06078
            ],
            [
              59.405795,
              18.060724
            ],
            [
              59.405686,
              18.060672
            ],
            [
              59.40549,
              18.060547
            ],
            [
              59.405347,
              18.060456
            ],
            [
              59.404739,
              18.060022
            ],
            [
              59.404699,
              18.059996
            ],
            [
              59.404658,
              18.059975
            ],
            [
              59.404481,
              18.059895
            ],
            [
              59.404397,
              18.059862
            ],
            [
              59.403346,
              18.059497
            ],
            [
              59.40303,
              18.0594
            ],
            [
              59.402945,
              18.059386
            ],
            [
              59.402522,
              18.05934
            ],
            [
              59.401952,
              18.059354
            ],
            [
              59.401877,
              18.059353
            ],
            [
              59.400763,
              18.059224
            ],
            [
              59.399264,
              18.058943
            ],
            [
              59.398988,
              18.058884
            ],
            [
              59.398578,
              18.058795
            ],
            [
              59.398515,
              18.058774
            ],
            [
              59.397963,
              18.058555
            ],
            [
              59.3979,
              18.058538
            ],
            [
              59.397709,
              18.058496
            ],
            [
              59.397068,
              18.058032
            ],
            [
              59.397038,
              18.058008
            ],
            [
              59.397,
              18.057973
            ],
            [
              59.39661,
              18.05756
            ],
            [
              59.396266,
              18.057142
            ],
            [
              59.396212,
              18.057075
            ],
            [
              59.396178,
              18.057026
            ],
            [
              59.396024,
              18.056768
            ],
            [
              59.395993,
              18.056712
            ],
            [
              59.395948,
              18.056621
            ],
            [
              59.395795,
              18.056301
            ],
            [
              59.395752,
              18.056207
            ],
            [
              59.395719,
              18.056124
            ],
            [
              59.395573,
              18.055733
            ],
            [
              59.395541,
              18.055647
            ],
            [
              59.395524,
              18.055594
            ],
            [
              59.395488,
              18.055467
            ],
            [
              59.395274,
              18.054701
            ],
            [
              59.39499,
              18.053527
            ],
            [
              59.394785,
              18.052764
            ],
            [
              59.394725,
              18.052544
            ],
            [
              59.394544,
              18.051909
            ],
            [
              59.394497,
              18.051747
            ],
            [
              59.394191,
              18.050817
            ],
            [
              59.394167,
              18.050748
            ],
            [
              59.394129,
              18.05065
            ],
            [
              59.393887,
              18.050049
            ],
            [
              59.393824,
              18.049908
            ],
            [
              59.393522,
              18.049264
            ],
            [
              59.393316,
              18.048884
            ],
            [
              59.393238,
              18.048744
            ],
            [
              59.393088,
              18.04848
            ],
            [
              59.393032,
              18.048385
            ],
            [
              59.392774,
              18.048007
            ],
            [
              59.392486,
              18.047618
            ],
            [
              59.392301,
              18.047405
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
      "tripDuration": 2160,
      "tripRtDuration": 2160,
      "rating": 0,
      "isAdditional": false,
      "interchanges": 0,
      "legs": [
        {
          "infos": [
            
          ],
          "duration": 2160,
          "origin": {
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
            "departureTimeBaseTimetable": "2026-09-01T19:12:00Z",
            "departureTimePlanned": "2026-09-01T19:12:00Z",
            "departureTimeEstimated": "2026-09-01T19:12:00Z",
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
            "id": "9025001000007142",
            "name": "Mörby, Danderyd",
            "disassembledName": "2",
            "type": "platform",
            "coord": [
              59.392339,
              18.047451
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
            "arrivalTimeBaseTimetable": "2026-09-01T19:48:00Z",
            "arrivalTimePlanned": "2026-09-01T19:48:00Z",
            "arrivalTimeEstimated": "2026-09-01T19:48:00Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "2",
              "platform": "1",
              "stoppingPointPlanned": "2",
              "platformName": "2",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "transportation": {
            "id": "tfs:03028: :H:y01",
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
              "id": "18006601",
              "name": "Stockholms östra",
              "type": "stop"
            },
            "properties": {
              "tripCode": 138,
              "timetablePeriod": "Current",
              "lineDisplay": "LINE",
              "globalId": "9011001002800000",
              "RealtimeTripId": "9015001002806179",
              "shortTrain": true
            },
            "isSamtrafik": false,
            "disassembledName": "28"
          },
          "stopSequence": [
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
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:12:00Z"
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
              "departureTimePlanned": "2026-09-01T19:13:00Z",
              "arrivalTimePlanned": "2026-09-01T19:13:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007073",
              "name": "Åkersberga, Österåker",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.478994,
                18.299886
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
                "area": "3",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T19:16:00Z",
              "arrivalTimePlanned": "2026-09-01T19:16:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007062",
              "name": "Åkers Runö, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.480618,
                18.270385
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:18:00Z",
              "arrivalTimePlanned": "2026-09-01T19:18:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007052",
              "name": "Täljö, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.473195,
                18.235432
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:21:00Z",
              "arrivalTimePlanned": "2026-09-01T19:21:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007041",
              "name": "Rydbo, Österåker",
              "disassembledName": "1",
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
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:25:00Z",
              "arrivalTimePlanned": "2026-09-01T19:25:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007036",
              "name": "Arninge, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.458809,
                18.141495
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:28:00Z",
              "arrivalTimePlanned": "2026-09-01T19:28:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007032",
              "name": "Hägernäs, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.450884,
                18.125182
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:30:00Z",
              "arrivalTimePlanned": "2026-09-01T19:30:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007021",
              "name": "Viggbyholm, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.449226,
                18.10417
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
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:33:00Z",
              "arrivalTimePlanned": "2026-09-01T19:33:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007012",
              "name": "Galoppfältet, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.446856,
                18.08518
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:34:00Z",
              "arrivalTimePlanned": "2026-09-01T19:34:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007002",
              "name": "Täby centrum, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.444368,
                18.07466
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:36:00Z",
              "arrivalTimePlanned": "2026-09-01T19:36:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007194",
              "name": "Roslags Näsby, Täby",
              "disassembledName": "4",
              "type": "platform",
              "coord": [
                59.435192,
                18.057404
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
                "area": "4",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "4",
                "platformName": "4"
              },
              "departureTimePlanned": "2026-09-01T19:39:00Z",
              "arrivalTimePlanned": "2026-09-01T19:39:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007182",
              "name": "Enebyberg, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.425853,
                18.051232
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:40:00Z",
              "arrivalTimePlanned": "2026-09-01T19:40:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007172",
              "name": "Djursholms Ekeby, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.412906,
                18.057655
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:42:00Z",
              "arrivalTimePlanned": "2026-09-01T19:42:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007162",
              "name": "Bråvallavägen, Danderyd",
              "disassembledName": "2",
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:44:00Z",
              "arrivalTimePlanned": "2026-09-01T19:44:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007153",
              "name": "Djursholms Ösby, Danderyd",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.399089,
                18.058958
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
                "area": "3",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T19:46:00Z",
              "arrivalTimePlanned": "2026-09-01T19:46:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007142",
              "name": "Mörby, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.392339,
                18.047451
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "arrivalTimePlanned": "2026-09-01T19:48:00Z"
            }
          ],
          "properties": {
            "tripId": "9015001002806179"
          },
          "coords": [
            [
              59.461364,
              18.311007
            ],
            [
              59.463482,
              18.308532
            ],
            [
              59.464733,
              18.307167
            ],
            [
              59.465201,
              18.306814
            ],
            [
              59.465639,
              18.306618
            ],
            [
              59.466565,
              18.306895
            ],
            [
              59.467732,
              18.307248
            ],
            [
              59.468755,
              18.307401
            ],
            [
              59.468737,
              18.307313
            ],
            [
              59.46884,
              18.307319
            ],
            [
              59.469078,
              18.307347
            ],
            [
              59.469289,
              18.307388
            ],
            [
              59.469481,
              18.307434
            ],
            [
              59.469803,
              18.307494
            ],
            [
              59.469855,
              18.307513
            ],
            [
              59.470073,
              18.307611
            ],
            [
              59.47081,
              18.3079
            ],
            [
              59.471405,
              18.308158
            ],
            [
              59.471847,
              18.308331
            ],
            [
              59.471908,
              18.308349
            ],
            [
              59.471978,
              18.308364
            ],
            [
              59.472309,
              18.308401
            ],
            [
              59.472371,
              18.308402
            ],
            [
              59.472548,
              18.308397
            ],
            [
              59.47277,
              18.308398
            ],
            [
              59.472812,
              18.308396
            ],
            [
              59.473316,
              18.308294
            ],
            [
              59.473495,
              18.308265
            ],
            [
              59.473569,
              18.30825
            ],
            [
              59.473771,
              18.308192
            ],
            [
              59.473953,
              18.308127
            ],
            [
              59.474014,
              18.308102
            ],
            [
              59.474185,
              18.308024
            ],
            [
              59.474236,
              18.307998
            ],
            [
              59.474442,
              18.307877
            ],
            [
              59.474523,
              18.307825
            ],
            [
              59.47462,
              18.307752
            ],
            [
              59.474667,
              18.307712
            ],
            [
              59.474846,
              18.307544
            ],
            [
              59.47492,
              18.307463
            ],
            [
              59.475132,
              18.307222
            ],
            [
              59.475176,
              18.307162
            ],
            [
              59.475366,
              18.306859
            ],
            [
              59.475616,
              18.306479
            ],
            [
              59.475688,
              18.306357
            ],
            [
              59.476021,
              18.305772
            ],
            [
              59.47646,
              18.305029
            ],
            [
              59.476857,
              18.304333
            ],
            [
              59.47732,
              18.303547
            ],
            [
              59.47736,
              18.303477
            ],
            [
              59.477401,
              18.3034
            ],
            [
              59.477448,
              18.303316
            ],
            [
              59.478413,
              18.30167
            ],
            [
              59.478459,
              18.301583
            ],
            [
              59.478546,
              18.301399
            ],
            [
              59.478632,
              18.301186
            ],
            [
              59.478668,
              18.301084
            ],
            [
              59.478791,
              18.3007
            ],
            [
              59.47888,
              18.300404
            ],
            [
              59.478905,
              18.300311
            ],
            [
              59.478945,
              18.30014
            ],
            [
              59.478991,
              18.299909
            ],
            [
              59.479018,
              18.299751
            ],
            [
              59.479061,
              18.299473
            ],
            [
              59.479119,
              18.298998
            ],
            [
              59.479299,
              18.297291
            ],
            [
              59.479392,
              18.296382
            ],
            [
              59.47951,
              18.295405
            ],
            [
              59.479578,
              18.294726
            ],
            [
              59.479646,
              18.294089
            ],
            [
              59.479736,
              18.293176
            ],
            [
              59.47976,
              18.29292
            ],
            [
              59.479838,
              18.292184
            ],
            [
              59.479882,
              18.291703
            ],
            [
              59.479934,
              18.291163
            ],
            [
              59.479987,
              18.290501
            ],
            [
              59.480023,
              18.289991
            ],
            [
              59.480035,
              18.289685
            ],
            [
              59.480047,
              18.289226
            ],
            [
              59.480061,
              18.288761
            ],
            [
              59.480202,
              18.281876
            ],
            [
              59.480249,
              18.27974
            ],
            [
              59.480258,
              18.279158
            ],
            [
              59.480271,
              18.278768
            ],
            [
              59.480276,
              18.278583
            ],
            [
              59.480337,
              18.275795
            ],
            [
              59.48036,
              18.274924
            ],
            [
              59.480368,
              18.274434
            ],
            [
              59.480372,
              18.274289
            ],
            [
              59.480392,
              18.273789
            ],
            [
              59.480399,
              18.273643
            ],
            [
              59.480434,
              18.273057
            ],
            [
              59.480451,
              18.272808
            ],
            [
              59.480487,
              18.272336
            ],
            [
              59.480592,
              18.271164
            ],
            [
              59.480626,
              18.27081
            ],
            [
              59.48066,
              18.270424
            ],
            [
              59.480697,
              18.270019
            ],
            [
              59.480773,
              18.269235
            ],
            [
              59.480789,
              18.269049
            ],
            [
              59.480895,
              18.267537
            ],
            [
              59.480923,
              18.267176
            ],
            [
              59.480942,
              18.266865
            ],
            [
              59.48095,
              18.266649
            ],
            [
              59.480951,
              18.266548
            ],
            [
              59.480947,
              18.266359
            ],
            [
              59.480934,
              18.265965
            ],
            [
              59.480928,
              18.265845
            ],
            [
              59.480915,
              18.265689
            ],
            [
              59.480888,
              18.26546
            ],
            [
              59.48085,
              18.265204
            ],
            [
              59.480837,
              18.265126
            ],
            [
              59.480783,
              18.264853
            ],
            [
              59.480766,
              18.264778
            ],
            [
              59.480734,
              18.264649
            ],
            [
              59.480695,
              18.264506
            ],
            [
              59.480621,
              18.264263
            ],
            [
              59.480531,
              18.264002
            ],
            [
              59.480507,
              18.263938
            ],
            [
              59.480482,
              18.263875
            ],
            [
              59.480391,
              18.263689
            ],
            [
              59.480291,
              18.263473
            ],
            [
              59.480223,
              18.263341
            ],
            [
              59.479889,
              18.262702
            ],
            [
              59.479486,
              18.261941
            ],
            [
              59.479265,
              18.261534
            ],
            [
              59.47912,
              18.261241
            ],
            [
              59.478985,
              18.261004
            ],
            [
              59.478802,
              18.260641
            ],
            [
              59.478703,
              18.260452
            ],
            [
              59.478545,
              18.260156
            ],
            [
              59.478366,
              18.259815
            ],
            [
              59.478315,
              18.25971
            ],
            [
              59.478202,
              18.259467
            ],
            [
              59.478089,
              18.259205
            ],
            [
              59.478005,
              18.258999
            ],
            [
              59.477961,
              18.258886
            ],
            [
              59.47787,
              18.258634
            ],
            [
              59.477829,
              18.258516
            ],
            [
              59.477739,
              18.258245
            ],
            [
              59.477617,
              18.257828
            ],
            [
              59.477598,
              18.257755
            ],
            [
              59.477486,
              18.257303
            ],
            [
              59.47745,
              18.257151
            ],
            [
              59.477376,
              18.256799
            ],
            [
              59.477323,
              18.25653
            ],
            [
              59.477273,
              18.256244
            ],
            [
              59.477251,
              18.256092
            ],
            [
              59.477235,
              18.255974
            ],
            [
              59.477184,
              18.255544
            ],
            [
              59.477119,
              18.254939
            ],
            [
              59.477045,
              18.254212
            ],
            [
              59.477033,
              18.254089
            ],
            [
              59.477015,
              18.253857
            ],
            [
              59.477004,
              18.253738
            ],
            [
              59.476921,
              18.252929
            ],
            [
              59.476799,
              18.251695
            ],
            [
              59.476737,
              18.251098
            ],
            [
              59.476683,
              18.250518
            ],
            [
              59.476568,
              18.249344
            ],
            [
              59.476492,
              18.248615
            ],
            [
              59.476433,
              18.247966
            ],
            [
              59.476357,
              18.247218
            ],
            [
              59.476329,
              18.246907
            ],
            [
              59.476296,
              18.246614
            ],
            [
              59.476228,
              18.245873
            ],
            [
              59.476169,
              18.245263
            ],
            [
              59.476134,
              18.244927
            ],
            [
              59.476095,
              18.24452
            ],
            [
              59.476044,
              18.24404
            ],
            [
              59.476004,
              18.243635
            ],
            [
              59.475934,
              18.24301
            ],
            [
              59.475873,
              18.242519
            ],
            [
              59.475797,
              18.242046
            ],
            [
              59.475719,
              18.241603
            ],
            [
              59.475693,
              18.241467
            ],
            [
              59.475635,
              18.241175
            ],
            [
              59.475551,
              18.240823
            ],
            [
              59.475507,
              18.240654
            ],
            [
              59.475482,
              18.240562
            ],
            [
              59.475249,
              18.23978
            ],
            [
              59.475062,
              18.239229
            ],
            [
              59.475026,
              18.239131
            ],
            [
              59.474791,
              18.238558
            ],
            [
              59.474668,
              18.238272
            ],
            [
              59.474571,
              18.238061
            ],
            [
              59.47445,
              18.237813
            ],
            [
              59.474082,
              18.237087
            ],
            [
              59.473977,
              18.236867
            ],
            [
              59.473577,
              18.23607
            ],
            [
              59.473369,
              18.23565
            ],
            [
              59.473238,
              18.23538
            ],
            [
              59.472753,
              18.234374
            ],
            [
              59.472531,
              18.233923
            ],
            [
              59.472425,
              18.233702
            ],
            [
              59.471404,
              18.231614
            ],
            [
              59.471299,
              18.231395
            ],
            [
              59.471247,
              18.231374
            ],
            [
              59.47126,
              18.231349
            ],
            [
              59.471183,
              18.231193
            ],
            [
              59.471118,
              18.23108
            ],
            [
              59.471,
              18.230812
            ],
            [
              59.470754,
              18.230278
            ],
            [
              59.470497,
              18.229648
            ],
            [
              59.470265,
              18.228776
            ],
            [
              59.470033,
              18.228074
            ],
            [
              59.469837,
              18.227178
            ],
            [
              59.469703,
              18.226645
            ],
            [
              59.469581,
              18.225968
            ],
            [
              59.469508,
              18.225411
            ],
            [
              59.469435,
              18.225024
            ],
            [
              59.469362,
              18.224395
            ],
            [
              59.469289,
              18.223839
            ],
            [
              59.469241,
              18.223234
            ],
            [
              59.469205,
              18.222654
            ],
            [
              59.469182,
              18.221807
            ],
            [
              59.469171,
              18.221082
            ],
            [
              59.469185,
              18.220115
            ],
            [
              59.469275,
              18.217747
            ],
            [
              59.469331,
              18.215987
            ],
            [
              59.469357,
              18.21577
            ],
            [
              59.469377,
              18.215568
            ],
            [
              59.469392,
              18.215397
            ],
            [
              59.469361,
              18.215391
            ],
            [
              59.469441,
              18.214147
            ],
            [
              59.469526,
              18.212486
            ],
            [
              59.469543,
              18.211945
            ],
            [
              59.469532,
              18.210615
            ],
            [
              59.469509,
              18.209914
            ],
            [
              59.469482,
              18.209373
            ],
            [
              59.46945,
              18.20893
            ],
            [
              59.469411,
              18.208472
            ],
            [
              59.469359,
              18.207897
            ],
            [
              59.469347,
              18.207775
            ],
            [
              59.469313,
              18.207471
            ],
            [
              59.469206,
              18.20656
            ],
            [
              59.469111,
              18.205804
            ],
            [
              59.469001,
              18.204843
            ],
            [
              59.468957,
              18.204536
            ],
            [
              59.468904,
              18.20414
            ],
            [
              59.468854,
              18.203717
            ],
            [
              59.468804,
              18.20332
            ],
            [
              59.468762,
              18.203016
            ],
            [
              59.468677,
              18.202426
            ],
            [
              59.468631,
              18.20214
            ],
            [
              59.468492,
              18.201394
            ],
            [
              59.468431,
              18.201082
            ],
            [
              59.4684,
              18.200933
            ],
            [
              59.468258,
              18.20029
            ],
            [
              59.467951,
              18.199079
            ],
            [
              59.467907,
              18.198911
            ],
            [
              59.467712,
              18.198264
            ],
            [
              59.467523,
              18.197675
            ],
            [
              59.467472,
              18.197512
            ],
            [
              59.466959,
              18.195827
            ],
            [
              59.46682,
              18.195362
            ],
            [
              59.466689,
              18.194939
            ],
            [
              59.466493,
              18.194283
            ],
            [
              59.46636,
              18.193819
            ],
            [
              59.466252,
              18.193453
            ],
            [
              59.466232,
              18.193379
            ],
            [
              59.466158,
              18.1931
            ],
            [
              59.466097,
              18.192858
            ],
            [
              59.466043,
              18.192635
            ],
            [
              59.465975,
              18.192339
            ],
            [
              59.4659,
              18.191974
            ],
            [
              59.465762,
              18.191228
            ],
            [
              59.465728,
              18.191029
            ],
            [
              59.465673,
              18.190645
            ],
            [
              59.465637,
              18.190418
            ],
            [
              59.465571,
              18.189949
            ],
            [
              59.465505,
              18.18938
            ],
            [
              59.465494,
              18.189278
            ],
            [
              59.465464,
              18.188955
            ],
            [
              59.465432,
              18.188531
            ],
            [
              59.465387,
              18.187677
            ],
            [
              59.465377,
              18.187339
            ],
            [
              59.465371,
              18.187033
            ],
            [
              59.465368,
              18.186744
            ],
            [
              59.465367,
              18.186534
            ],
            [
              59.465385,
              18.185873
            ],
            [
              59.465349,
              18.185926
            ],
            [
              59.465534,
              18.183609
            ],
            [
              59.465842,
              18.181493
            ],
            [
              59.466305,
              18.179644
            ],
            [
              59.466834,
              18.177674
            ],
            [
              59.467319,
              18.176206
            ],
            [
              59.467673,
              18.174851
            ],
            [
              59.467965,
              18.173427
            ],
            [
              59.468197,
              18.171809
            ],
            [
              59.468297,
              18.170304
            ],
            [
              59.46824,
              18.168721
            ],
            [
              59.468025,
              18.166997
            ],
            [
              59.467486,
              18.16537
            ],
            [
              59.466932,
              18.164371
            ],
            [
              59.466188,
              18.163292
            ],
            [
              59.465541,
              18.162159
            ],
            [
              59.465068,
              18.160475
            ],
            [
              59.464183,
              18.157238
            ],
            [
              59.463522,
              18.154022
            ],
            [
              59.463046,
              18.151139
            ],
            [
              59.462451,
              18.147866
            ],
            [
              59.461941,
              18.146368
            ],
            [
              59.460524,
              18.143902
            ],
            [
              59.458813,
              18.141599
            ],
            [
              59.4588,
              18.14157
            ],
            [
              59.458179,
              18.140801
            ],
            [
              59.45725,
              18.139585
            ],
            [
              59.456104,
              18.138517
            ],
            [
              59.454501,
              18.136987
            ],
            [
              59.453288,
              18.136038
            ],
            [
              59.45214,
              18.135053
            ],
            [
              59.451033,
              18.134156
            ],
            [
              59.450293,
              18.133041
            ],
            [
              59.44988,
              18.131623
            ],
            [
              59.449774,
              18.129814
            ],
            [
              59.450097,
              18.127878
            ],
            [
              59.450695,
              18.126051
            ],
            [
              59.450927,
              18.125235
            ],
            [
              59.450895,
              18.125213
            ],
            [
              59.45099,
              18.124833
            ],
            [
              59.451069,
              18.124488
            ],
            [
              59.451102,
              18.124337
            ],
            [
              59.451221,
              18.123768
            ],
            [
              59.45126,
              18.123573
            ],
            [
              59.451304,
              18.123337
            ],
            [
              59.451364,
              18.122982
            ],
            [
              59.451523,
              18.121962
            ],
            [
              59.45162,
              18.121352
            ],
            [
              59.451685,
              18.120881
            ],
            [
              59.451773,
              18.12029
            ],
            [
              59.451945,
              18.119091
            ],
            [
              59.452043,
              18.118354
            ],
            [
              59.452111,
              18.117868
            ],
            [
              59.452133,
              18.117728
            ],
            [
              59.452252,
              18.117013
            ],
            [
              59.452352,
              18.11649
            ],
            [
              59.452376,
              18.116375
            ],
            [
              59.45257,
              18.11548
            ],
            [
              59.452709,
              18.114872
            ],
            [
              59.452805,
              18.114442
            ],
            [
              59.452875,
              18.11409
            ],
            [
              59.452922,
              18.113814
            ],
            [
              59.452939,
              18.113677
            ],
            [
              59.45298,
              18.113232
            ],
            [
              59.452988,
              18.113108
            ],
            [
              59.452996,
              18.11286
            ],
            [
              59.452998,
              18.112619
            ],
            [
              59.452994,
              18.112432
            ],
            [
              59.452981,
              18.112135
            ],
            [
              59.452962,
              18.111846
            ],
            [
              59.452952,
              18.111745
            ],
            [
              59.452928,
              18.111571
            ],
            [
              59.452902,
              18.111394
            ],
            [
              59.452877,
              18.111233
            ],
            [
              59.452815,
              18.110905
            ],
            [
              59.4528,
              18.110834
            ],
            [
              59.452786,
              18.110779
            ],
            [
              59.452701,
              18.110477
            ],
            [
              59.45258,
              18.110092
            ],
            [
              59.452537,
              18.109975
            ],
            [
              59.452461,
              18.109779
            ],
            [
              59.452428,
              18.1097
            ],
            [
              59.452401,
              18.109641
            ],
            [
              59.452323,
              18.109486
            ],
            [
              59.452221,
              18.109294
            ],
            [
              59.451791,
              18.108556
            ],
            [
              59.451406,
              18.107944
            ],
            [
              59.451112,
              18.107436
            ],
            [
              59.450658,
              18.106753
            ],
            [
              59.450337,
              18.106303
            ],
            [
              59.450288,
              18.106222
            ],
            [
              59.45015,
              18.105984
            ],
            [
              59.449776,
              18.105317
            ],
            [
              59.449722,
              18.105214
            ],
            [
              59.449476,
              18.104656
            ],
            [
              59.449268,
              18.104143
            ],
            [
              59.449062,
              18.103631
            ],
            [
              59.448946,
              18.103308
            ],
            [
              59.448839,
              18.103017
            ],
            [
              59.448821,
              18.102965
            ],
            [
              59.448793,
              18.102878
            ],
            [
              59.448731,
              18.102666
            ],
            [
              59.448695,
              18.102539
            ],
            [
              59.448628,
              18.102281
            ],
            [
              59.448588,
              18.102113
            ],
            [
              59.448561,
              18.10198
            ],
            [
              59.448435,
              18.101299
            ],
            [
              59.448375,
              18.100908
            ],
            [
              59.448348,
              18.100711
            ],
            [
              59.448287,
              18.100206
            ],
            [
              59.448277,
              18.100105
            ],
            [
              59.448244,
              18.09978
            ],
            [
              59.448204,
              18.099351
            ],
            [
              59.448164,
              18.098903
            ],
            [
              59.448144,
              18.09871
            ],
            [
              59.447986,
              18.0968
            ],
            [
              59.447844,
              18.095138
            ],
            [
              59.447786,
              18.09454
            ],
            [
              59.447739,
              18.093984
            ],
            [
              59.447486,
              18.091157
            ],
            [
              59.447376,
              18.089998
            ],
            [
              59.447291,
              18.089118
            ],
            [
              59.447094,
              18.087033
            ],
            [
              59.446937,
              18.08517
            ],
            [
              59.44689,
              18.084704
            ],
            [
              59.446831,
              18.084192
            ],
            [
              59.446785,
              18.083847
            ],
            [
              59.446746,
              18.083608
            ],
            [
              59.446731,
              18.083529
            ],
            [
              59.446706,
              18.083406
            ],
            [
              59.446557,
              18.082709
            ],
            [
              59.446472,
              18.082338
            ],
            [
              59.446383,
              18.081935
            ],
            [
              59.446307,
              18.081624
            ],
            [
              59.445716,
              18.079265
            ],
            [
              59.444774,
              18.07578
            ],
            [
              59.444741,
              18.075672
            ],
            [
              59.444556,
              18.075132
            ],
            [
              59.444519,
              18.075031
            ],
            [
              59.44438,
              18.07469
            ],
            [
              59.444275,
              18.074433
            ],
            [
              59.444233,
              18.074339
            ],
            [
              59.443476,
              18.072719
            ],
            [
              59.442478,
              18.070591
            ],
            [
              59.441877,
              18.069292
            ],
            [
              59.438196,
              18.061471
            ],
            [
              59.438144,
              18.061364
            ],
            [
              59.438114,
              18.061305
            ],
            [
              59.437693,
              18.060528
            ],
            [
              59.437654,
              18.060458
            ],
            [
              59.437612,
              18.060395
            ],
            [
              59.437502,
              18.060242
            ],
            [
              59.437453,
              18.060169
            ],
            [
              59.437338,
              18.059996
            ],
            [
              59.437118,
              18.059658
            ],
            [
              59.437029,
              18.059526
            ],
            [
              59.436985,
              18.05947
            ],
            [
              59.436817,
              18.059265
            ],
            [
              59.436155,
              18.058595
            ],
            [
              59.435707,
              18.058075
            ],
            [
              59.435646,
              18.057993
            ],
            [
              59.435358,
              18.05758
            ],
            [
              59.435294,
              18.057472
            ],
            [
              59.435146,
              18.05721
            ],
            [
              59.435098,
              18.057129
            ],
            [
              59.435049,
              18.05705
            ],
            [
              59.434525,
              18.056229
            ],
            [
              59.43406,
              18.055432
            ],
            [
              59.433421,
              18.054343
            ],
            [
              59.433045,
              18.053729
            ],
            [
              59.432971,
              18.053611
            ],
            [
              59.432727,
              18.053234
            ],
            [
              59.432425,
              18.052809
            ],
            [
              59.43239,
              18.052763
            ],
            [
              59.432344,
              18.052708
            ],
            [
              59.432111,
              18.052447
            ],
            [
              59.431613,
              18.051959
            ],
            [
              59.431545,
              18.0519
            ],
            [
              59.43128,
              18.051692
            ],
            [
              59.431044,
              18.051507
            ],
            [
              59.430994,
              18.051471
            ],
            [
              59.430922,
              18.051433
            ],
            [
              59.430629,
              18.051297
            ],
            [
              59.430272,
              18.051163
            ],
            [
              59.430209,
              18.051142
            ],
            [
              59.430114,
              18.051124
            ],
            [
              59.429742,
              18.051074
            ],
            [
              59.429667,
              18.051067
            ],
            [
              59.428057,
              18.051076
            ],
            [
              59.427046,
              18.051123
            ],
            [
              59.426407,
              18.051175
            ],
            [
              59.425975,
              18.051238
            ],
            [
              59.425754,
              18.051253
            ],
            [
              59.425233,
              18.051288
            ],
            [
              59.424631,
              18.051316
            ],
            [
              59.424058,
              18.051254
            ],
            [
              59.423749,
              18.051202
            ],
            [
              59.423686,
              18.051188
            ],
            [
              59.423613,
              18.05116
            ],
            [
              59.423406,
              18.051072
            ],
            [
              59.423324,
              18.051032
            ],
            [
              59.422078,
              18.050263
            ],
            [
              59.421986,
              18.05021
            ],
            [
              59.4216,
              18.050046
            ],
            [
              59.421538,
              18.050024
            ],
            [
              59.420835,
              18.049813
            ],
            [
              59.420751,
              18.04979
            ],
            [
              59.420516,
              18.049749
            ],
            [
              59.420452,
              18.049741
            ],
            [
              59.420086,
              18.049736
            ],
            [
              59.420011,
              18.049738
            ],
            [
              59.419872,
              18.049764
            ],
            [
              59.41968,
              18.049817
            ],
            [
              59.419595,
              18.049843
            ],
            [
              59.419512,
              18.049875
            ],
            [
              59.419439,
              18.049906
            ],
            [
              59.419175,
              18.05004
            ],
            [
              59.419096,
              18.050091
            ],
            [
              59.418957,
              18.050186
            ],
            [
              59.418908,
              18.050224
            ],
            [
              59.418858,
              18.050266
            ],
            [
              59.418475,
              18.050596
            ],
            [
              59.418377,
              18.050684
            ],
            [
              59.417887,
              18.051142
            ],
            [
              59.417578,
              18.05146
            ],
            [
              59.417329,
              18.051691
            ],
            [
              59.416875,
              18.052141
            ],
            [
              59.416793,
              18.052236
            ],
            [
              59.41638,
              18.052746
            ],
            [
              59.416321,
              18.052834
            ],
            [
              59.416018,
              18.05332
            ],
            [
              59.415978,
              18.053388
            ],
            [
              59.415956,
              18.053433
            ],
            [
              59.415395,
              18.054658
            ],
            [
              59.415011,
              18.055579
            ],
            [
              59.41496,
              18.055684
            ],
            [
              59.414758,
              18.056079
            ],
            [
              59.414697,
              18.056193
            ],
            [
              59.414553,
              18.056426
            ],
            [
              59.414494,
              18.056513
            ],
            [
              59.414416,
              18.056622
            ],
            [
              59.414356,
              18.056695
            ],
            [
              59.414286,
              18.056773
            ],
            [
              59.414148,
              18.056906
            ],
            [
              59.414037,
              18.057004
            ],
            [
              59.414,
              18.057034
            ],
            [
              59.413971,
              18.057054
            ],
            [
              59.41387,
              18.05711
            ],
            [
              59.413774,
              18.057158
            ],
            [
              59.413361,
              18.057385
            ],
            [
              59.413061,
              18.057545
            ],
            [
              59.412803,
              18.057676
            ],
            [
              59.411807,
              18.058177
            ],
            [
              59.409913,
              18.059183
            ],
            [
              59.408757,
              18.059768
            ],
            [
              59.406992,
              18.060649
            ],
            [
              59.406849,
              18.060723
            ],
            [
              59.406797,
              18.060746
            ],
            [
              59.406723,
              18.060771
            ],
            [
              59.406607,
              18.060801
            ],
            [
              59.406459,
              18.060823
            ],
            [
              59.406386,
              18.060828
            ],
            [
              59.406185,
              18.060827
            ],
            [
              59.406089,
              18.060818
            ],
            [
              59.406048,
              18.06081
            ],
            [
              59.405946,
              18.06078
            ],
            [
              59.405795,
              18.060724
            ],
            [
              59.405686,
              18.060672
            ],
            [
              59.40549,
              18.060547
            ],
            [
              59.405347,
              18.060456
            ],
            [
              59.404739,
              18.060022
            ],
            [
              59.404699,
              18.059996
            ],
            [
              59.404658,
              18.059975
            ],
            [
              59.404481,
              18.059895
            ],
            [
              59.404397,
              18.059862
            ],
            [
              59.403346,
              18.059497
            ],
            [
              59.40303,
              18.0594
            ],
            [
              59.402945,
              18.059386
            ],
            [
              59.402522,
              18.05934
            ],
            [
              59.401952,
              18.059354
            ],
            [
              59.401877,
              18.059353
            ],
            [
              59.400763,
              18.059224
            ],
            [
              59.399264,
              18.058943
            ],
            [
              59.398988,
              18.058884
            ],
            [
              59.398578,
              18.058795
            ],
            [
              59.398515,
              18.058774
            ],
            [
              59.397963,
              18.058555
            ],
            [
              59.3979,
              18.058538
            ],
            [
              59.397709,
              18.058496
            ],
            [
              59.397068,
              18.058032
            ],
            [
              59.397038,
              18.058008
            ],
            [
              59.397,
              18.057973
            ],
            [
              59.39661,
              18.05756
            ],
            [
              59.396266,
              18.057142
            ],
            [
              59.396212,
              18.057075
            ],
            [
              59.396178,
              18.057026
            ],
            [
              59.396024,
              18.056768
            ],
            [
              59.395993,
              18.056712
            ],
            [
              59.395948,
              18.056621
            ],
            [
              59.395795,
              18.056301
            ],
            [
              59.395752,
              18.056207
            ],
            [
              59.395719,
              18.056124
            ],
            [
              59.395573,
              18.055733
            ],
            [
              59.395541,
              18.055647
            ],
            [
              59.395524,
              18.055594
            ],
            [
              59.395488,
              18.055467
            ],
            [
              59.395274,
              18.054701
            ],
            [
              59.39499,
              18.053527
            ],
            [
              59.394785,
              18.052764
            ],
            [
              59.394725,
              18.052544
            ],
            [
              59.394544,
              18.051909
            ],
            [
              59.394497,
              18.051747
            ],
            [
              59.394191,
              18.050817
            ],
            [
              59.394167,
              18.050748
            ],
            [
              59.394129,
              18.05065
            ],
            [
              59.393887,
              18.050049
            ],
            [
              59.393824,
              18.049908
            ],
            [
              59.393522,
              18.049264
            ],
            [
              59.393316,
              18.048884
            ],
            [
              59.393238,
              18.048744
            ],
            [
              59.393088,
              18.04848
            ],
            [
              59.393032,
              18.048385
            ],
            [
              59.392774,
              18.048007
            ],
            [
              59.392486,
              18.047618
            ],
            [
              59.392301,
              18.047405
            ]
          ]
        }
      ],
      "daysOfService": {
        "rvb": "000000000003CF9F7CF800004F9F3E7C39F3E7CF3E7CF9F327CF9F3E000007CF"
      }
    },
    {
      "tripDuration": 2160,
      "tripRtDuration": 2160,
      "rating": 0,
      "isAdditional": false,
      "interchanges": 0,
      "legs": [
        {
          "infos": [
            
          ],
          "duration": 2160,
          "origin": {
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
            "departureTimeBaseTimetable": "2026-09-01T19:42:00Z",
            "departureTimePlanned": "2026-09-01T19:42:00Z",
            "departureTimeEstimated": "2026-09-01T19:42:00Z",
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
            "id": "9025001000007142",
            "name": "Mörby, Danderyd",
            "disassembledName": "2",
            "type": "platform",
            "coord": [
              59.392339,
              18.047451
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
            "arrivalTimeBaseTimetable": "2026-09-01T20:18:00Z",
            "arrivalTimePlanned": "2026-09-01T20:18:00Z",
            "arrivalTimeEstimated": "2026-09-01T20:18:00Z",
            "properties": {
              "AREA_NIVEAU_DIVA": "0",
              "area": "2",
              "platform": "1",
              "stoppingPointPlanned": "2",
              "platformName": "2",
              "callType": [
                "ONDEMAND"
              ]
            }
          },
          "transportation": {
            "id": "tfs:03028: :H:y01",
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
              "id": "18006601",
              "name": "Stockholms östra",
              "type": "stop"
            },
            "properties": {
              "tripCode": 263,
              "timetablePeriod": "Current",
              "lineDisplay": "LINE",
              "globalId": "9011001002800000",
              "RealtimeTripId": "9015001002806181",
              "shortTrain": true
            },
            "isSamtrafik": false,
            "disassembledName": "28"
          },
          "stopSequence": [
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
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:42:00Z"
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
              "departureTimePlanned": "2026-09-01T19:43:00Z",
              "arrivalTimePlanned": "2026-09-01T19:43:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007073",
              "name": "Åkersberga, Österåker",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.478994,
                18.299886
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
                "area": "3",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T19:46:00Z",
              "arrivalTimePlanned": "2026-09-01T19:46:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007062",
              "name": "Åkers Runö, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.480618,
                18.270385
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:48:00Z",
              "arrivalTimePlanned": "2026-09-01T19:48:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007052",
              "name": "Täljö, Österåker",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.473195,
                18.235432
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:51:00Z",
              "arrivalTimePlanned": "2026-09-01T19:51:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007041",
              "name": "Rydbo, Österåker",
              "disassembledName": "1",
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
                "area": "1",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "1",
                "platformName": "1"
              },
              "departureTimePlanned": "2026-09-01T19:55:00Z",
              "arrivalTimePlanned": "2026-09-01T19:55:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007036",
              "name": "Arninge, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.458809,
                18.141495
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T19:58:00Z",
              "arrivalTimePlanned": "2026-09-01T19:58:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007032",
              "name": "Hägernäs, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.450884,
                18.125182
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T20:00:00Z",
              "arrivalTimePlanned": "2026-09-01T20:00:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007021",
              "name": "Viggbyholm, Täby",
              "disassembledName": "1",
              "type": "platform",
              "coord": [
                59.449226,
                18.10417
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
              "id": "9025001000007012",
              "name": "Galoppfältet, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.446856,
                18.08518
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T20:04:00Z",
              "arrivalTimePlanned": "2026-09-01T20:04:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007002",
              "name": "Täby centrum, Täby",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.444368,
                18.07466
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T20:06:00Z",
              "arrivalTimePlanned": "2026-09-01T20:06:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007194",
              "name": "Roslags Näsby, Täby",
              "disassembledName": "4",
              "type": "platform",
              "coord": [
                59.435192,
                18.057404
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
                "area": "4",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:488",
                "stoppingPointPlanned": "4",
                "platformName": "4"
              },
              "departureTimePlanned": "2026-09-01T20:09:00Z",
              "arrivalTimePlanned": "2026-09-01T20:09:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007182",
              "name": "Enebyberg, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.425853,
                18.051232
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T20:10:00Z",
              "arrivalTimePlanned": "2026-09-01T20:10:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007172",
              "name": "Djursholms Ekeby, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.412906,
                18.057655
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T20:12:00Z",
              "arrivalTimePlanned": "2026-09-01T20:12:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007162",
              "name": "Bråvallavägen, Danderyd",
              "disassembledName": "2",
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
                "area": "2",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "departureTimePlanned": "2026-09-01T20:14:00Z",
              "arrivalTimePlanned": "2026-09-01T20:14:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007153",
              "name": "Djursholms Ösby, Danderyd",
              "disassembledName": "3",
              "type": "platform",
              "coord": [
                59.399089,
                18.058958
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
                "area": "3",
                "occupancy": "MANY_SEATS",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "3",
                "platformName": "3"
              },
              "departureTimePlanned": "2026-09-01T20:16:00Z",
              "arrivalTimePlanned": "2026-09-01T20:16:00Z"
            },
            {
              "isGlobalId": true,
              "id": "9025001000007142",
              "name": "Mörby, Danderyd",
              "disassembledName": "2",
              "type": "platform",
              "coord": [
                59.392339,
                18.047451
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
                "area": "2",
                "platform": "1",
                "zone": "tfs:34",
                "stoppingPointPlanned": "2",
                "platformName": "2"
              },
              "arrivalTimePlanned": "2026-09-01T20:18:00Z"
            }
          ],
          "properties": {
            "tripId": "9015001002806181"
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
              59.461364,
              18.311007
            ],
            [
              59.463482,
              18.308532
            ],
            [
              59.464733,
              18.307167
            ],
            [
              59.465201,
              18.306814
            ],
            [
              59.465639,
              18.306618
            ],
            [
              59.466565,
              18.306895
            ],
            [
              59.467732,
              18.307248
            ],
            [
              59.468755,
              18.307401
            ],
            [
              59.468737,
              18.307313
            ],
            [
              59.46884,
              18.307319
            ],
            [
              59.469078,
              18.307347
            ],
            [
              59.469289,
              18.307388
            ],
            [
              59.469481,
              18.307434
            ],
            [
              59.469803,
              18.307494
            ],
            [
              59.469855,
              18.307513
            ],
            [
              59.470073,
              18.307611
            ],
            [
              59.47081,
              18.3079
            ],
            [
              59.471405,
              18.308158
            ],
            [
              59.471847,
              18.308331
            ],
            [
              59.471908,
              18.308349
            ],
            [
              59.471978,
              18.308364
            ],
            [
              59.472309,
              18.308401
            ],
            [
              59.472371,
              18.308402
            ],
            [
              59.472548,
              18.308397
            ],
            [
              59.47277,
              18.308398
            ],
            [
              59.472812,
              18.308396
            ],
            [
              59.473316,
              18.308294
            ],
            [
              59.473495,
              18.308265
            ],
            [
              59.473569,
              18.30825
            ],
            [
              59.473771,
              18.308192
            ],
            [
              59.473953,
              18.308127
            ],
            [
              59.474014,
              18.308102
            ],
            [
              59.474185,
              18.308024
            ],
            [
              59.474236,
              18.307998
            ],
            [
              59.474442,
              18.307877
            ],
            [
              59.474523,
              18.307825
            ],
            [
              59.47462,
              18.307752
            ],
            [
              59.474667,
              18.307712
            ],
            [
              59.474846,
              18.307544
            ],
            [
              59.47492,
              18.307463
            ],
            [
              59.475132,
              18.307222
            ],
            [
              59.475176,
              18.307162
            ],
            [
              59.475366,
              18.306859
            ],
            [
              59.475616,
              18.306479
            ],
            [
              59.475688,
              18.306357
            ],
            [
              59.476021,
              18.305772
            ],
            [
              59.47646,
              18.305029
            ],
            [
              59.476857,
              18.304333
            ],
            [
              59.47732,
              18.303547
            ],
            [
              59.47736,
              18.303477
            ],
            [
              59.477401,
              18.3034
            ],
            [
              59.477448,
              18.303316
            ],
            [
              59.478413,
              18.30167
            ],
            [
              59.478459,
              18.301583
            ],
            [
              59.478546,
              18.301399
            ],
            [
              59.478632,
              18.301186
            ],
            [
              59.478668,
              18.301084
            ],
            [
              59.478791,
              18.3007
            ],
            [
              59.47888,
              18.300404
            ],
            [
              59.478905,
              18.300311
            ],
            [
              59.478945,
              18.30014
            ],
            [
              59.478991,
              18.299909
            ],
            [
              59.479018,
              18.299751
            ],
            [
              59.479061,
              18.299473
            ],
            [
              59.479119,
              18.298998
            ],
            [
              59.479299,
              18.297291
            ],
            [
              59.479392,
              18.296382
            ],
            [
              59.47951,
              18.295405
            ],
            [
              59.479578,
              18.294726
            ],
            [
              59.479646,
              18.294089
            ],
            [
              59.479736,
              18.293176
            ],
            [
              59.47976,
              18.29292
            ],
            [
              59.479838,
              18.292184
            ],
            [
              59.479882,
              18.291703
            ],
            [
              59.479934,
              18.291163
            ],
            [
              59.479987,
              18.290501
            ],
            [
              59.480023,
              18.289991
            ],
            [
              59.480035,
              18.289685
            ],
            [
              59.480047,
              18.289226
            ],
            [
              59.480061,
              18.288761
            ],
            [
              59.480202,
              18.281876
            ],
            [
              59.480249,
              18.27974
            ],
            [
              59.480258,
              18.279158
            ],
            [
              59.480271,
              18.278768
            ],
            [
              59.480276,
              18.278583
            ],
            [
              59.480337,
              18.275795
            ],
            [
              59.48036,
              18.274924
            ],
            [
              59.480368,
              18.274434
            ],
            [
              59.480372,
              18.274289
            ],
            [
              59.480392,
              18.273789
            ],
            [
              59.480399,
              18.273643
            ],
            [
              59.480434,
              18.273057
            ],
            [
              59.480451,
              18.272808
            ],
            [
              59.480487,
              18.272336
            ],
            [
              59.480592,
              18.271164
            ],
            [
              59.480626,
              18.27081
            ],
            [
              59.48066,
              18.270424
            ],
            [
              59.480697,
              18.270019
            ],
            [
              59.480773,
              18.269235
            ],
            [
              59.480789,
              18.269049
            ],
            [
              59.480895,
              18.267537
            ],
            [
              59.480923,
              18.267176
            ],
            [
              59.480942,
              18.266865
            ],
            [
              59.48095,
              18.266649
            ],
            [
              59.480951,
              18.266548
            ],
            [
              59.480947,
              18.266359
            ],
            [
              59.480934,
              18.265965
            ],
            [
              59.480928,
              18.265845
            ],
            [
              59.480915,
              18.265689
            ],
            [
              59.480888,
              18.26546
            ],
            [
              59.48085,
              18.265204
            ],
            [
              59.480837,
              18.265126
            ],
            [
              59.480783,
              18.264853
            ],
            [
              59.480766,
              18.264778
            ],
            [
              59.480734,
              18.264649
            ],
            [
              59.480695,
              18.264506
            ],
            [
              59.480621,
              18.264263
            ],
            [
              59.480531,
              18.264002
            ],
            [
              59.480507,
              18.263938
            ],
            [
              59.480482,
              18.263875
            ],
            [
              59.480391,
              18.263689
            ],
            [
              59.480291,
              18.263473
            ],
            [
              59.480223,
              18.263341
            ],
            [
              59.479889,
              18.262702
            ],
            [
              59.479486,
              18.261941
            ],
            [
              59.479265,
              18.261534
            ],
            [
              59.47912,
              18.261241
            ],
            [
              59.478985,
              18.261004
            ],
            [
              59.478802,
              18.260641
            ],
            [
              59.478703,
              18.260452
            ],
            [
              59.478545,
              18.260156
            ],
            [
              59.478366,
              18.259815
            ],
            [
              59.478315,
              18.25971
            ],
            [
              59.478202,
              18.259467
            ],
            [
              59.478089,
              18.259205
            ],
            [
              59.478005,
              18.258999
            ],
            [
              59.477961,
              18.258886
            ],
            [
              59.47787,
              18.258634
            ],
            [
              59.477829,
              18.258516
            ],
            [
              59.477739,
              18.258245
            ],
            [
              59.477617,
              18.257828
            ],
            [
              59.477598,
              18.257755
            ],
            [
              59.477486,
              18.257303
            ],
            [
              59.47745,
              18.257151
            ],
            [
              59.477376,
              18.256799
            ],
            [
              59.477323,
              18.25653
            ],
            [
              59.477273,
              18.256244
            ],
            [
              59.477251,
              18.256092
            ],
            [
              59.477235,
              18.255974
            ],
            [
              59.477184,
              18.255544
            ],
            [
              59.477119,
              18.254939
            ],
            [
              59.477045,
              18.254212
            ],
            [
              59.477033,
              18.254089
            ],
            [
              59.477015,
              18.253857
            ],
            [
              59.477004,
              18.253738
            ],
            [
              59.476921,
              18.252929
            ],
            [
              59.476799,
              18.251695
            ],
            [
              59.476737,
              18.251098
            ],
            [
              59.476683,
              18.250518
            ],
            [
              59.476568,
              18.249344
            ],
            [
              59.476492,
              18.248615
            ],
            [
              59.476433,
              18.247966
            ],
            [
              59.476357,
              18.247218
            ],
            [
              59.476329,
              18.246907
            ],
            [
              59.476296,
              18.246614
            ],
            [
              59.476228,
              18.245873
            ],
            [
              59.476169,
              18.245263
            ],
            [
              59.476134,
              18.244927
            ],
            [
              59.476095,
              18.24452
            ],
            [
              59.476044,
              18.24404
            ],
            [
              59.476004,
              18.243635
            ],
            [
              59.475934,
              18.24301
            ],
            [
              59.475873,
              18.242519
            ],
            [
              59.475797,
              18.242046
            ],
            [
              59.475719,
              18.241603
            ],
            [
              59.475693,
              18.241467
            ],
            [
              59.475635,
              18.241175
            ],
            [
              59.475551,
              18.240823
            ],
            [
              59.475507,
              18.240654
            ],
            [
              59.475482,
              18.240562
            ],
            [
              59.475249,
              18.23978
            ],
            [
              59.475062,
              18.239229
            ],
            [
              59.475026,
              18.239131
            ],
            [
              59.474791,
              18.238558
            ],
            [
              59.474668,
              18.238272
            ],
            [
              59.474571,
              18.238061
            ],
            [
              59.47445,
              18.237813
            ],
            [
              59.474082,
              18.237087
            ],
            [
              59.473977,
              18.236867
            ],
            [
              59.473577,
              18.23607
            ],
            [
              59.473369,
              18.23565
            ],
            [
              59.473238,
              18.23538
            ],
            [
              59.472753,
              18.234374
            ],
            [
              59.472531,
              18.233923
            ],
            [
              59.472425,
              18.233702
            ],
            [
              59.471404,
              18.231614
            ],
            [
              59.471299,
              18.231395
            ],
            [
              59.471247,
              18.231374
            ],
            [
              59.47126,
              18.231349
            ],
            [
              59.471183,
              18.231193
            ],
            [
              59.471118,
              18.23108
            ],
            [
              59.471,
              18.230812
            ],
            [
              59.470754,
              18.230278
            ],
            [
              59.470497,
              18.229648
            ],
            [
              59.470265,
              18.228776
            ],
            [
              59.470033,
              18.228074
            ],
            [
              59.469837,
              18.227178
            ],
            [
              59.469703,
              18.226645
            ],
            [
              59.469581,
              18.225968
            ],
            [
              59.469508,
              18.225411
            ],
            [
              59.469435,
              18.225024
            ],
            [
              59.469362,
              18.224395
            ],
            [
              59.469289,
              18.223839
            ],
            [
              59.469241,
              18.223234
            ],
            [
              59.469205,
              18.222654
            ],
            [
              59.469182,
              18.221807
            ],
            [
              59.469171,
              18.221082
            ],
            [
              59.469185,
              18.220115
            ],
            [
              59.469275,
              18.217747
            ],
            [
              59.469331,
              18.215987
            ],
            [
              59.469357,
              18.21577
            ],
            [
              59.469377,
              18.215568
            ],
            [
              59.469392,
              18.215397
            ],
            [
              59.469361,
              18.215391
            ],
            [
              59.469441,
              18.214147
            ],
            [
              59.469526,
              18.212486
            ],
            [
              59.469543,
              18.211945
            ],
            [
              59.469532,
              18.210615
            ],
            [
              59.469509,
              18.209914
            ],
            [
              59.469482,
              18.209373
            ],
            [
              59.46945,
              18.20893
            ],
            [
              59.469411,
              18.208472
            ],
            [
              59.469359,
              18.207897
            ],
            [
              59.469347,
              18.207775
            ],
            [
              59.469313,
              18.207471
            ],
            [
              59.469206,
              18.20656
            ],
            [
              59.469111,
              18.205804
            ],
            [
              59.469001,
              18.204843
            ],
            [
              59.468957,
              18.204536
            ],
            [
              59.468904,
              18.20414
            ],
            [
              59.468854,
              18.203717
            ],
            [
              59.468804,
              18.20332
            ],
            [
              59.468762,
              18.203016
            ],
            [
              59.468677,
              18.202426
            ],
            [
              59.468631,
              18.20214
            ],
            [
              59.468492,
              18.201394
            ],
            [
              59.468431,
              18.201082
            ],
            [
              59.4684,
              18.200933
            ],
            [
              59.468258,
              18.20029
            ],
            [
              59.467951,
              18.199079
            ],
            [
              59.467907,
              18.198911
            ],
            [
              59.467712,
              18.198264
            ],
            [
              59.467523,
              18.197675
            ],
            [
              59.467472,
              18.197512
            ],
            [
              59.466959,
              18.195827
            ],
            [
              59.46682,
              18.195362
            ],
            [
              59.466689,
              18.194939
            ],
            [
              59.466493,
              18.194283
            ],
            [
              59.46636,
              18.193819
            ],
            [
              59.466252,
              18.193453
            ],
            [
              59.466232,
              18.193379
            ],
            [
              59.466158,
              18.1931
            ],
            [
              59.466097,
              18.192858
            ],
            [
              59.466043,
              18.192635
            ],
            [
              59.465975,
              18.192339
            ],
            [
              59.4659,
              18.191974
            ],
            [
              59.465762,
              18.191228
            ],
            [
              59.465728,
              18.191029
            ],
            [
              59.465673,
              18.190645
            ],
            [
              59.465637,
              18.190418
            ],
            [
              59.465571,
              18.189949
            ],
            [
              59.465505,
              18.18938
            ],
            [
              59.465494,
              18.189278
            ],
            [
              59.465464,
              18.188955
            ],
            [
              59.465432,
              18.188531
            ],
            [
              59.465387,
              18.187677
            ],
            [
              59.465377,
              18.187339
            ],
            [
              59.465371,
              18.187033
            ],
            [
              59.465368,
              18.186744
            ],
            [
              59.465367,
              18.186534
            ],
            [
              59.465385,
              18.185873
            ],
            [
              59.465349,
              18.185926
            ],
            [
              59.465534,
              18.183609
            ],
            [
              59.465842,
              18.181493
            ],
            [
              59.466305,
              18.179644
            ],
            [
              59.466834,
              18.177674
            ],
            [
              59.467319,
              18.176206
            ],
            [
              59.467673,
              18.174851
            ],
            [
              59.467965,
              18.173427
            ],
            [
              59.468197,
              18.171809
            ],
            [
              59.468297,
              18.170304
            ],
            [
              59.46824,
              18.168721
            ],
            [
              59.468025,
              18.166997
            ],
            [
              59.467486,
              18.16537
            ],
            [
              59.466932,
              18.164371
            ],
            [
              59.466188,
              18.163292
            ],
            [
              59.465541,
              18.162159
            ],
            [
              59.465068,
              18.160475
            ],
            [
              59.464183,
              18.157238
            ],
            [
              59.463522,
              18.154022
            ],
            [
              59.463046,
              18.151139
            ],
            [
              59.462451,
              18.147866
            ],
            [
              59.461941,
              18.146368
            ],
            [
              59.460524,
              18.143902
            ],
            [
              59.458813,
              18.141599
            ],
            [
              59.4588,
              18.14157
            ],
            [
              59.458179,
              18.140801
            ],
            [
              59.45725,
              18.139585
            ],
            [
              59.456104,
              18.138517
            ],
            [
              59.454501,
              18.136987
            ],
            [
              59.453288,
              18.136038
            ],
            [
              59.45214,
              18.135053
            ],
            [
              59.451033,
              18.134156
            ],
            [
              59.450293,
              18.133041
            ],
            [
              59.44988,
              18.131623
            ],
            [
              59.449774,
              18.129814
            ],
            [
              59.450097,
              18.127878
            ],
            [
              59.450695,
              18.126051
            ],
            [
              59.450927,
              18.125235
            ],
            [
              59.450895,
              18.125213
            ],
            [
              59.45099,
              18.124833
            ],
            [
              59.451069,
              18.124488
            ],
            [
              59.451102,
              18.124337
            ],
            [
              59.451221,
              18.123768
            ],
            [
              59.45126,
              18.123573
            ],
            [
              59.451304,
              18.123337
            ],
            [
              59.451364,
              18.122982
            ],
            [
              59.451523,
              18.121962
            ],
            [
              59.45162,
              18.121352
            ],
            [
              59.451685,
              18.120881
            ],
            [
              59.451773,
              18.12029
            ],
            [
              59.451945,
              18.119091
            ],
            [
              59.452043,
              18.118354
            ],
            [
              59.452111,
              18.117868
            ],
            [
              59.452133,
              18.117728
            ],
            [
              59.452252,
              18.117013
            ],
            [
              59.452352,
              18.11649
            ],
            [
              59.452376,
              18.116375
            ],
            [
              59.45257,
              18.11548
            ],
            [
              59.452709,
              18.114872
            ],
            [
              59.452805,
              18.114442
            ],
            [
              59.452875,
              18.11409
            ],
            [
              59.452922,
              18.113814
            ],
            [
              59.452939,
              18.113677
            ],
            [
              59.45298,
              18.113232
            ],
            [
              59.452988,
              18.113108
            ],
            [
              59.452996,
              18.11286
            ],
            [
              59.452998,
              18.112619
            ],
            [
              59.452994,
              18.112432
            ],
            [
              59.452981,
              18.112135
            ],
            [
              59.452962,
              18.111846
            ],
            [
              59.452952,
              18.111745
            ],
            [
              59.452928,
              18.111571
            ],
            [
              59.452902,
              18.111394
            ],
            [
              59.452877,
              18.111233
            ],
            [
              59.452815,
              18.110905
            ],
            [
              59.4528,
              18.110834
            ],
            [
              59.452786,
              18.110779
            ],
            [
              59.452701,
              18.110477
            ],
            [
              59.45258,
              18.110092
            ],
            [
              59.452537,
              18.109975
            ],
            [
              59.452461,
              18.109779
            ],
            [
              59.452428,
              18.1097
            ],
            [
              59.452401,
              18.109641
            ],
            [
              59.452323,
              18.109486
            ],
            [
              59.452221,
              18.109294
            ],
            [
              59.451791,
              18.108556
            ],
            [
              59.451406,
              18.107944
            ],
            [
              59.451112,
              18.107436
            ],
            [
              59.450658,
              18.106753
            ],
            [
              59.450337,
              18.106303
            ],
            [
              59.450288,
              18.106222
            ],
            [
              59.45015,
              18.105984
            ],
            [
              59.449776,
              18.105317
            ],
            [
              59.449722,
              18.105214
            ],
            [
              59.449476,
              18.104656
            ],
            [
              59.449268,
              18.104143
            ],
            [
              59.449062,
              18.103631
            ],
            [
              59.448946,
              18.103308
            ],
            [
              59.448839,
              18.103017
            ],
            [
              59.448821,
              18.102965
            ],
            [
              59.448793,
              18.102878
            ],
            [
              59.448731,
              18.102666
            ],
            [
              59.448695,
              18.102539
            ],
            [
              59.448628,
              18.102281
            ],
            [
              59.448588,
              18.102113
            ],
            [
              59.448561,
              18.10198
            ],
            [
              59.448435,
              18.101299
            ],
            [
              59.448375,
              18.100908
            ],
            [
              59.448348,
              18.100711
            ],
            [
              59.448287,
              18.100206
            ],
            [
              59.448277,
              18.100105
            ],
            [
              59.448244,
              18.09978
            ],
            [
              59.448204,
              18.099351
            ],
            [
              59.448164,
              18.098903
            ],
            [
              59.448144,
              18.09871
            ],
            [
              59.447986,
              18.0968
            ],
            [
              59.447844,
              18.095138
            ],
            [
              59.447786,
              18.09454
            ],
            [
              59.447739,
              18.093984
            ],
            [
              59.447486,
              18.091157
            ],
            [
              59.447376,
              18.089998
            ],
            [
              59.447291,
              18.089118
            ],
            [
              59.447094,
              18.087033
            ],
            [
              59.446937,
              18.08517
            ],
            [
              59.44689,
              18.084704
            ],
            [
              59.446831,
              18.084192
            ],
            [
              59.446785,
              18.083847
            ],
            [
              59.446746,
              18.083608
            ],
            [
              59.446731,
              18.083529
            ],
            [
              59.446706,
              18.083406
            ],
            [
              59.446557,
              18.082709
            ],
            [
              59.446472,
              18.082338
            ],
            [
              59.446383,
              18.081935
            ],
            [
              59.446307,
              18.081624
            ],
            [
              59.445716,
              18.079265
            ],
            [
              59.444774,
              18.07578
            ],
            [
              59.444741,
              18.075672
            ],
            [
              59.444556,
              18.075132
            ],
            [
              59.444519,
              18.075031
            ],
            [
              59.44438,
              18.07469
            ],
            [
              59.444275,
              18.074433
            ],
            [
              59.444233,
              18.074339
            ],
            [
              59.443476,
              18.072719
            ],
            [
              59.442478,
              18.070591
            ],
            [
              59.441877,
              18.069292
            ],
            [
              59.438196,
              18.061471
            ],
            [
              59.438144,
              18.061364
            ],
            [
              59.438114,
              18.061305
            ],
            [
              59.437693,
              18.060528
            ],
            [
              59.437654,
              18.060458
            ],
            [
              59.437612,
              18.060395
            ],
            [
              59.437502,
              18.060242
            ],
            [
              59.437453,
              18.060169
            ],
            [
              59.437338,
              18.059996
            ],
            [
              59.437118,
              18.059658
            ],
            [
              59.437029,
              18.059526
            ],
            [
              59.436985,
              18.05947
            ],
            [
              59.436817,
              18.059265
            ],
            [
              59.436155,
              18.058595
            ],
            [
              59.435707,
              18.058075
            ],
            [
              59.435646,
              18.057993
            ],
            [
              59.435358,
              18.05758
            ],
            [
              59.435294,
              18.057472
            ],
            [
              59.435146,
              18.05721
            ],
            [
              59.435098,
              18.057129
            ],
            [
              59.435049,
              18.05705
            ],
            [
              59.434525,
              18.056229
            ],
            [
              59.43406,
              18.055432
            ],
            [
              59.433421,
              18.054343
            ],
            [
              59.433045,
              18.053729
            ],
            [
              59.432971,
              18.053611
            ],
            [
              59.432727,
              18.053234
            ],
            [
              59.432425,
              18.052809
            ],
            [
              59.43239,
              18.052763
            ],
            [
              59.432344,
              18.052708
            ],
            [
              59.432111,
              18.052447
            ],
            [
              59.431613,
              18.051959
            ],
            [
              59.431545,
              18.0519
            ],
            [
              59.43128,
              18.051692
            ],
            [
              59.431044,
              18.051507
            ],
            [
              59.430994,
              18.051471
            ],
            [
              59.430922,
              18.051433
            ],
            [
              59.430629,
              18.051297
            ],
            [
              59.430272,
              18.051163
            ],
            [
              59.430209,
              18.051142
            ],
            [
              59.430114,
              18.051124
            ],
            [
              59.429742,
              18.051074
            ],
            [
              59.429667,
              18.051067
            ],
            [
              59.428057,
              18.051076
            ],
            [
              59.427046,
              18.051123
            ],
            [
              59.426407,
              18.051175
            ],
            [
              59.425975,
              18.051238
            ],
            [
              59.425754,
              18.051253
            ],
            [
              59.425233,
              18.051288
            ],
            [
              59.424631,
              18.051316
            ],
            [
              59.424058,
              18.051254
            ],
            [
              59.423749,
              18.051202
            ],
            [
              59.423686,
              18.051188
            ],
            [
              59.423613,
              18.05116
            ],
            [
              59.423406,
              18.051072
            ],
            [
              59.423324,
              18.051032
            ],
            [
              59.422078,
              18.050263
            ],
            [
              59.421986,
              18.05021
            ],
            [
              59.4216,
              18.050046
            ],
            [
              59.421538,
              18.050024
            ],
            [
              59.420835,
              18.049813
            ],
            [
              59.420751,
              18.04979
            ],
            [
              59.420516,
              18.049749
            ],
            [
              59.420452,
              18.049741
            ],
            [
              59.420086,
              18.049736
            ],
            [
              59.420011,
              18.049738
            ],
            [
              59.419872,
              18.049764
            ],
            [
              59.41968,
              18.049817
            ],
            [
              59.419595,
              18.049843
            ],
            [
              59.419512,
              18.049875
            ],
            [
              59.419439,
              18.049906
            ],
            [
              59.419175,
              18.05004
            ],
            [
              59.419096,
              18.050091
            ],
            [
              59.418957,
              18.050186
            ],
            [
              59.418908,
              18.050224
            ],
            [
              59.418858,
              18.050266
            ],
            [
              59.418475,
              18.050596
            ],
            [
              59.418377,
              18.050684
            ],
            [
              59.417887,
              18.051142
            ],
            [
              59.417578,
              18.05146
            ],
            [
              59.417329,
              18.051691
            ],
            [
              59.416875,
              18.052141
            ],
            [
              59.416793,
              18.052236
            ],
            [
              59.41638,
              18.052746
            ],
            [
              59.416321,
              18.052834
            ],
            [
              59.416018,
              18.05332
            ],
            [
              59.415978,
              18.053388
            ],
            [
              59.415956,
              18.053433
            ],
            [
              59.415395,
              18.054658
            ],
            [
              59.415011,
              18.055579
            ],
            [
              59.41496,
              18.055684
            ],
            [
              59.414758,
              18.056079
            ],
            [
              59.414697,
              18.056193
            ],
            [
              59.414553,
              18.056426
            ],
            [
              59.414494,
              18.056513
            ],
            [
              59.414416,
              18.056622
            ],
            [
              59.414356,
              18.056695
            ],
            [
              59.414286,
              18.056773
            ],
            [
              59.414148,
              18.056906
            ],
            [
              59.414037,
              18.057004
            ],
            [
              59.414,
              18.057034
            ],
            [
              59.413971,
              18.057054
            ],
            [
              59.41387,
              18.05711
            ],
            [
              59.413774,
              18.057158
            ],
            [
              59.413361,
              18.057385
            ],
            [
              59.413061,
              18.057545
            ],
            [
              59.412803,
              18.057676
            ],
            [
              59.411807,
              18.058177
            ],
            [
              59.409913,
              18.059183
            ],
            [
              59.408757,
              18.059768
            ],
            [
              59.406992,
              18.060649
            ],
            [
              59.406849,
              18.060723
            ],
            [
              59.406797,
              18.060746
            ],
            [
              59.406723,
              18.060771
            ],
            [
              59.406607,
              18.060801
            ],
            [
              59.406459,
              18.060823
            ],
            [
              59.406386,
              18.060828
            ],
            [
              59.406185,
              18.060827
            ],
            [
              59.406089,
              18.060818
            ],
            [
              59.406048,
              18.06081
            ],
            [
              59.405946,
              18.06078
            ],
            [
              59.405795,
              18.060724
            ],
            [
              59.405686,
              18.060672
            ],
            [
              59.40549,
              18.060547
            ],
            [
              59.405347,
              18.060456
            ],
            [
              59.404739,
              18.060022
            ],
            [
              59.404699,
              18.059996
            ],
            [
              59.404658,
              18.059975
            ],
            [
              59.404481,
              18.059895
            ],
            [
              59.404397,
              18.059862
            ],
            [
              59.403346,
              18.059497
            ],
            [
              59.40303,
              18.0594
            ],
            [
              59.402945,
              18.059386
            ],
            [
              59.402522,
              18.05934
            ],
            [
              59.401952,
              18.059354
            ],
            [
              59.401877,
              18.059353
            ],
            [
              59.400763,
              18.059224
            ],
            [
              59.399264,
              18.058943
            ],
            [
              59.398988,
              18.058884
            ],
            [
              59.398578,
              18.058795
            ],
            [
              59.398515,
              18.058774
            ],
            [
              59.397963,
              18.058555
            ],
            [
              59.3979,
              18.058538
            ],
            [
              59.397709,
              18.058496
            ],
            [
              59.397068,
              18.058032
            ],
            [
              59.397038,
              18.058008
            ],
            [
              59.397,
              18.057973
            ],
            [
              59.39661,
              18.05756
            ],
            [
              59.396266,
              18.057142
            ],
            [
              59.396212,
              18.057075
            ],
            [
              59.396178,
              18.057026
            ],
            [
              59.396024,
              18.056768
            ],
            [
              59.395993,
              18.056712
            ],
            [
              59.395948,
              18.056621
            ],
            [
              59.395795,
              18.056301
            ],
            [
              59.395752,
              18.056207
            ],
            [
              59.395719,
              18.056124
            ],
            [
              59.395573,
              18.055733
            ],
            [
              59.395541,
              18.055647
            ],
            [
              59.395524,
              18.055594
            ],
            [
              59.395488,
              18.055467
            ],
            [
              59.395274,
              18.054701
            ],
            [
              59.39499,
              18.053527
            ],
            [
              59.394785,
              18.052764
            ],
            [
              59.394725,
              18.052544
            ],
            [
              59.394544,
              18.051909
            ],
            [
              59.394497,
              18.051747
            ],
            [
              59.394191,
              18.050817
            ],
            [
              59.394167,
              18.050748
            ],
            [
              59.394129,
              18.05065
            ],
            [
              59.393887,
              18.050049
            ],
            [
              59.393824,
              18.049908
            ],
            [
              59.393522,
              18.049264
            ],
            [
              59.393316,
              18.048884
            ],
            [
              59.393238,
              18.048744
            ],
            [
              59.393088,
              18.04848
            ],
            [
              59.393032,
              18.048385
            ],
            [
              59.392774,
              18.048007
            ],
            [
              59.392486,
              18.047618
            ],
            [
              59.392301,
              18.047405
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
```