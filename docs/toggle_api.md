# Toggl api:

The main API (not reports) has limits:
- 1 request / second
- 1000 entries returned at most, not paginated

https://github.com/toggl/toggl_api_docs/blob/master/chapters/time_entries.md

## All entries in time range

http --auth abcd01234:api_token https://api.track.toggl.com/api/v8/time_entries?start_date=2021-12-01T00%3A00%3A00%2B07%3A00

```json
[
    {
        "at": "2021-12-01T15:44:52+00:00",
        "billable": false,
        "description": "Updates",
        "duration": 112,
        "duronly": false,
        "guid": "498488dec2a3f1298371d06223a0207e",
        "id": 2275435081,
        "pid": 51870923,
        "start": "2021-12-01T15:43:00+00:00",
        "stop": "2021-12-01T15:44:52+00:00",
        "uid": 2130859,
        "wid": 1352395
    },
    ...
]
```

## Currently running entry (if any)

http --auth abcd01234:api_token https://api.track.toggl.com/api/v8/time_entries/current

```json
{
    "data": {
        "at": "2021-12-06T19:15:20+00:00",
        "billable": false,
        "description": "Design",
        "duration": -1638817684,
        "duronly": false,
        "id": 2281700054,
        "pid": 177367363,
        "start": "2021-12-06T19:08:03+00:00",
        "uid": 2130859,
        "wid": 1352395
    }
}
```

## Project detail

http --auth abcd01234:api_token https://api.track.toggl.com/api/v8/projects/14171959

```json
{
    "data": {
        "active": true,
        "actual_hours": 310,
        "at": "2020-06-09T02:13:23+00:00",
        "auto_estimates": false,
        "billable": false,
        "color": "3",
        "created_at": "2016-02-29T11:52:16+00:00",
        "guid": "68400b31-5a17-4f47-bd3f-e291685f7788",
        "hex_color": "#e36a00",
        "id": 14171959,
        "is_private": true,
        "name": "IAD",
        "template": false,
        "wid": 1352395
    }
}
```


