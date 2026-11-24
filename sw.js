const CACHE='northbound-2027-v2.4';
const PHOTO='northbound-viewed-photos-v1';
const CORE=['/','/index.html','/mobile.css','/manifest.webmanifest','/assets/icon-192.png','/assets/icon-512.png'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)));self.skipWaiting()});
self.addEventListener('activate',event=>{event.waitUntil(Promise.all([caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE&&k!==PHOTO).map(k=>caches.delete(k)))),self.clients.claim()]))});
self.addEventListener('fetch',event=>{
 const r=event.request;if(r.method!=='GET')return;const url=new URL(r.url);
 if(url.hostname==='images.unsplash.com'||url.hostname==='upload.wikimedia.org'){
   // Cache images the user has already viewed (never map tiles or personally-uploaded files).
   event.respondWith(caches.open(PHOTO).then(async cache=>{let hit=await cache.match(r);try{let response=await fetch(r);if(response.ok||response.type==='opaque')cache.put(r,response.clone());return response}catch{return hit||Response.error()}}));return;
 }
 if(url.origin!==location.origin||url.pathname.startsWith('/api/'))return;
 event.respondWith(fetch(r).then(response=>{if(response.ok){const copy=response.clone();caches.open(CACHE).then(c=>c.put(r,copy))}return response}).catch(()=>caches.match(r).then(x=>x||caches.match('/index.html'))));
});
