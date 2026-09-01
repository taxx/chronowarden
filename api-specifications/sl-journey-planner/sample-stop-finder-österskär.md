Request:
https://journeyplanner.integration.sl.se/v2/stop-finder?name_sf=%C3%B6stersk%C3%A4r&any_obj_filter_sf=2&type_sf=any 

Response:
```json
{
  "locations": [
    {
      "coord": [
        59.461544,
        18.310621
      ],
      "disassembledName": "Österskär",
      "id": "9091001000009660",
      "isBest": true,
      "isGlobalId": true,
      "matchQuality": 1000,
      "name": "Österåker, Österskär",
      "parent": {
        "id": "placeID:33001017:1",
        "name": "Österåker",
        "type": "locality"
      },
      "productClasses": [
        4,
        5
      ],
      "properties": {
        "mainLocality": "Österåker",
        "stopId": "18009660"
      },
      "type": "stop"
    },
    {
      "coord": [
        59.461544,
        18.310621
      ],
      "disassembledName": "Österskärs station",
      "id": "9091001001009660",
      "isBest": false,
      "isGlobalId": true,
      "matchQuality": 888,
      "name": "Österåker, Österskärs station",
      "parent": {
        "id": "placeID:33001017:1",
        "name": "Österåker",
        "type": "locality"
      },
      "productClasses": [
        4,
        5
      ],
      "properties": {
        "mainLocality": "Österåker",
        "stopId": "18009670"
      },
      "type": "stop"
    }
  ],
  "systemMessages": [
    {
      "code": -8011,
      "module": "BROKER",
      "text": "",
      "type": "error"
    }
  ]
}
```
