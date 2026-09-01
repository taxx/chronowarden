Request:
https://journeyplanner.integration.sl.se/v2/stop-finder?name_sf=m%C3%B6rby%20station&any_obj_filter_sf=2&type_sf=any 

Response:
```json
{
  "locations": [
    {
      "coord": [
        59.392252,
        18.046813
      ],
      "disassembledName": "Mörby station",
      "id": "9091001001009638",
      "isBest": true,
      "isGlobalId": true,
      "matchQuality": 1000,
      "name": "Danderyd, Mörby station",
      "parent": {
        "id": "placeID:33001062:1",
        "name": "Danderyd",
        "type": "locality"
      },
      "productClasses": [
        4,
        5
      ],
      "properties": {
        "mainLocality": "Danderyd",
        "stopId": "18009645"
      },
      "type": "stop"
    }
  ],
  "systemMessages": [
    {
      "code": -8010,
      "module": "BROKER",
      "text": "Any - input uniquely verified",
      "type": "message"
    }
  ]
}
```
