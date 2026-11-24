# NORTHBOUND — India Trip 2027 (Vercel-ready)

Responsive installable trip companion for **14 January–2 February 2027**. Starts in Trivandrum, boards 16367 at Nagercoil on Jan 14, includes Varanasi / Agra / Jaipur / Jaisalmer & Sam Sand Dunes, and the **Kedarkantha Jan 23–27 trek** (must reach Dehradun by **09:00 Jan 23**). The train-only Kashmir variant includes a short **Gulmarg beginner skiing session** and one suggested heated room, no dorms. A Mumbai transfer is an optional higher-risk alternative; Shimla and Darjeeling are not in the time-limited core itinerary, but can be added in Trip Studio.

**Status:** A functional app, not a ticket-booking or background GPS service. Published train timings are PLANNED and must be checked when booking. Train seat counts are not fabricated.

## Fastest deployment to Vercel

1. Extract the ZIP so `index.html`, `api/`, `assets/`, `sw.js`, `supabase/`, `manifest.webmanifest` and `vercel.json` are all at the **project root**.
2. Upload these files to a new GitHub repository, then select **Vercel → New Project → Import Git Repository**.
3. Framework preset **Other**. Do not add a build command; publish the root directory (the static `index.html` and the Vercel functions in `api/`).
4. Open the HTTPS `*.vercel.app` URL. On a phone, use browser **Add to Home Screen** / **Install App**.
5. In **Trip Studio**, add an activity or new destination. Data is saved immediately in local browser storage.

You can also use the Vercel CLI: `npx vercel --prod` from this folder after authenticating. Neither a build step nor a runtime npm dependency is required. `package.json` uses ESM for the API functions.

## Full feature checklist

- Original 20-day itinerary, 24 hourly rows per day, date selection, user-created activities with editable start/end and notes.
- User-editable route stops with search for coordinates, GPS-based stop creation, manual latitude/longitude, ordered stop list, remove optional stops.
- Leaflet + OpenStreetMap route map with numbered markers; browser GPS watch with explicit Start/Stop. GPS is active only while the web page is open and the device/browser permits it.
- Distance table showing **straight-line geographical minimum** for each consecutive destination. For real roads use the `Road km` buttons or opt-in GPS live road estimate (road kilometres / road ETA, **not train kilometres**). Real rail distances may be shown for live rail provider results, if supplied.
- Next destination selector, station codes, live rail service/seat lookup behind optional API credentials, live running status, station display board, authorized PNR lookup, IRCTC/NTES fallback links.
- Ticket records with train number, date, origin/destination, coach, berth, price, status, notes, private reference. PDF/image copies are saved in IndexedDB in the browser, not auto-uploaded.
- INR expenses with categories and subcategories, custom or equal splits, group balances and manually recorded repayment confirmations, budgets and analytics, receipts, CSV/JSON exports.
- Optional authenticated Supabase shared groups, invite codes, per-expense rows, Realtime synchronization and group updates. JSON document state uses last-write-wins for simultaneous edits.
- Trip Coach with rule-based schedule, booking, skiing and overspending suggestions; a personal improvement idea queue.
- Journal with text notes / images, packing checklist, emergency contact and 112 / 139 quick links, nearby hospitals/stations, local weather for the NEXT 7 DAYS via Open-Meteo, photo galleries, calendar ICS, print-to-PDF.
- Offline PWA shell; previously viewed destination images may be cached. Maps, new images, live trains, live weather, distance lookups and group sync need an internet connection.

## Optional 1: live train services, seat availability, platform data, PNR

- Obtain a legitimate API key for a **rail enquiry provider** whose license permits your use. This package contains an **example adapter** for [`irctc.dev`](https://irctc.dev/docs/), which is a third-party service, **not the official IRCTC website**. Verify the provider's availability, pricing and reliability independently.
- In Vercel **Project → Settings → Environment Variables**, set `RAIL_API_KEY` and redeploy. The key is used only on the server in `api/trains.js` and `api/pnr.js`, never stored in HTML, localStorage or `public-config.js`.
- `api/trains` supports `search`, `availability`, `running`, and `station` enquiry modes. `api/pnr` only responds to a deliberate POST after user consent. All live results indicate source and retrieval time, and are **not booking confirmation**.
- Without a key the screens show **not configured** and link to [official IRCTC search](https://www.irctc.co.in/nget/train-search) and [NTES](https://enquiry.indianrail.gov.in/ntes/). This fallback is intentional: a Vercel site has no privileged access to IRCTC's reservation inventory.
- Official access to IRCTC's TIES train information system for organizations requires enrollment; see [official policy](https://contents.irctc.co.in/en/TIES_Policy.pdf).

## Optional 2: real road kilometres and ETA

- `api/road.js` supports [OpenRouteService](https://openrouteservice.org/) directions when `ORS_API_KEY` is set in Vercel Environment Variables. Add the key and redeploy.
- With no key, low-volume lookups use the **public OSRM demo**, which has limited availability and **must not be depended on for production traffic**. For a larger group install an ORS key, obtain permission for more requests, or host your own router.
- Important: a requested road ETA is for a **drivable route**, not a train trip, trek, or winter-condition forecast. Live location coordinates are submitted to routing infrastructure ONLY if you click **Calculate live road ETA**. Destination-to-destination `Road km` checks submit those two fixed destination coordinates.

## Optional 3: secure shared groups across friends' phones

1. Create a project at [Supabase](https://supabase.com/). Under **SQL Editor**, execute **`supabase/schema.sql`** once. It creates 4 tables, group creation/join RPC functions, Row Level Security policies and realtime publication entries.
2. In Supabase → Authentication → Providers, enable **Email**. In Authentication → URL Configuration, include your Vercel URL (`https://your-app.vercel.app/**`) in permitted redirect URLs.
3. In **Shared Group** inside the app, enter your Supabase **Project URL** and **public anon/publishable key**. These values are intentionally public client configuration; never use a service-role or secret key.
4. Send yourself a magic email link; sign in, create the trip group, and privately share the generated invite code. Your friends sign in and join the same group from their phones.
5. Shared expense rows sync through Supabase Realtime. Member names, budgets, custom routes, activities, journal text and booking metadata are shared. **PNR/reference fields and sensitive personal emergency contacts are deliberately not uploaded by the cloud sync.** Receipts and journal photo binaries remain local unless a separate private file-sharing backend is added.
6. Use **Sync now** if connectivity was interrupted. Avoid simultaneous edits to the **same** itinerary document: multi-person expense records have individual IDs, while other shared settings are last-write-wins.

### Security and privacy

- The browser needs HTTPS and location permission for GPS. Background tracking while the phone is locked or the browser is closed **is not provided** by the web app.
- Sensitive PNR references in the *local* booking manager are stored in your browser and may be included in a full JSON backup. Treat exported files as private and avoid public devices.
- Group invite codes grant membership to anyone who has the code and an authenticated account; share them only with people you trust.
- Personal GPS positions are never synced to a group. Road routing sends coordinates only after explicit action; live status and rail enquiries transmit station codes and dates to the configured provider.
- Email login, Supabase account access and railway query credentials are not preconfigured, because they require your own accounts. No ticket is booked, no settlement is paid, and no emergency notification is automatically sent.
- Weather data is a 7-day near-term forecast; a reliable specific forecast for January 2027 is not available until close to travel.
- Offline caching stores site pages and previously viewed public destination images; it does **not** automatically cache copyrighted map tiles, arbitrary internet content, live services or user files across devices.

## Included project files

`index.html` — fully interactive single HTML app (scripts and styles embedded). `api/road.js`, `api/weather.js`, `api/trains.js`, `api/pnr.js` — Vercel endpoints. `supabase/schema.sql` — optional secured database setup. `sw.js`, `manifest.webmanifest`, `assets/` — PWA. `.env.example` — optional server-only credentials. `FEATURES.md` — capability matrix. Developer sources `enhancements.js`, `cloud.js`, `new_views.html`, `build_app.py` are included to edit and rebuild the single-file UI.

## Testing and known limitations

- JavaScript syntax checked with Node v22. Browser smoke test verified day editor (24 rows), 17th added destination, 12 navigation tabs, expense saving, and trip-coach warnings. Test browser had restricted external networking, so live map tiles/images/providers were not verified end-to-end.
- The rail API, Supabase Realtime, PNR, Geocoding and route endpoints require a live HTTPS deployment and their upstream providers; test with real credentials after deployment.
- Dates and rail timetable data are **planning references** and some transfers are high-risk. The Jan 23 morning Dehradun arrival must be confirmed with the trek organiser. The Jan 27 return and Jan 29 Jammu connection need contingencies. Gulmarg skiing depends on winter-road access and instructor availability.
