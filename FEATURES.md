# Feature readiness — NORTHBOUND 2.4

| Feature | Shipped behavior | Requires setup? |
|---|---|---|
| Day-by-day itinerary | 20 days + editable 24 hourly rows, custom timed activities | No |
| Places and galleries | Destination photos, adding/editing/reordering stops, searchable coordinates | Internet for photos/geocoder |
| Map and GPS | Leaflet + browser geolocation, explicit opt-in, directions links | HTTPS + location consent + internet |
| Leg distance and duration | Great-circle minimum; requested road km and ETA; published rail times | Road API/connection for routed km; rail provider for rail km |
| Live trains and seats | Train search, class availability lookup, live running status, station board, optional PNR | Railway API key required |
| Tickets | Booking records, statuses, coach/berth, files | No; files stay on device |
| Expenses and splits | Categorized expenses, custom shares, settled repayments | No |
| Cross-device collaboration | Email auth, invite codes, per-expense sync | Supabase project/schema |
| Expense analytics | Daily spend, category budgets, payers, CSV | No |
| Trip Coach | Schedule alerts, budget warnings, readiness, improvement backlog | No |
| Travel journal and photos | Notes + IndexedDB images, gallery | No; new photos stay on device |
| Weather | Current conditions and next 7 days | Internet; Open-Meteo |
| Emergency | 112/139, manual GPS link, nearby hospitals/stations | GPS for proximity |
| PWA offline | App shell and viewed photos | Deploy to HTTPS; install |
| Export | JSON, CSV, ICS, print-to-PDF | No |

**Not claimed as implemented:** official ticket booking or guaranteed live availability without a provider, map turn-by-turn rendering inside the app, GPS tracking while closed, offline rail queries/tiles, native push notifications, automated payment confirmation, private cloud file storage, snow-safe traffic guarantees. These depend on integrations, device permissions, contracts or separate infrastructure.
