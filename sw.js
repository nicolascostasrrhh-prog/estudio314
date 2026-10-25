/* Estudio 3.14: cache únicamente de recursos públicos; datos de clientes nunca se almacenan aquí. */
const CACHE='estudio314-shell-v1';
const ASSETS=['./app-icon.svg','./manifest.webmanifest'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS)));self.skipWaiting()});
self.addEventListener('activate',event=>{event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith('estudio314-shell-')&&key!==CACHE).map(key=>caches.delete(key)))));self.clients.claim()});
self.addEventListener('fetch',event=>{const request=event.request;if(request.method!=='GET'||new URL(request.url).origin!==self.location.origin)return;if(!ASSETS.some(file=>new URL(file,self.registration.scope).pathname===new URL(request.url).pathname))return;event.respondWith(caches.match(request).then(hit=>hit||fetch(request)))});
