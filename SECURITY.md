# Security

DaysCounter holds full read access to your calendars, which can hold private appointments, names and places. It shares what it reads with its widget through an App Group, and it opens events from `dayscounter://` links. It makes no network requests.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Report it privately through GitHub: **Security → Report a vulnerability** on this repository ([direct link](https://github.com/nervouna/dayscounter/security/advisories/new)). Include what you did, what happened, and the commit you tested.

You will get an answer within a week. Fixes land on `main`; there are no maintained release branches.

## In scope

- Calendar data leaving the device, or reaching another app
- A way for the app or widget to change or delete calendar events
- A `dayscounter://` link that does anything beyond opening an event in the app

## Out of scope

- Anything that needs an unlocked device or a build you signed with changed code
- What other apps can read once you grant them calendar access
