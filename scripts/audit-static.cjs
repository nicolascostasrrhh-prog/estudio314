// Auditoría estática reproducible para Estudio 3.14. No crea usuarios ni toca datos reales.
const fs=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const index=fs.readFileSync('index.html','utf8');
const cases=[];
function check(name,fn){try{fn();cases.push({name,ok:true});console.log('OK  '+name)}catch(e){cases.push({name,ok:false});console.error('FAIL '+name+': '+e.message)}}
check('Estructura HTML y estilos',()=>{assert.match(index,/<!doctype html>/i);assert.equal((index.match(/<style\b/gi)||[]).length,(index.match(/<\/style>/gi)||[]).length);});
check('Scripts embebidos compilan',()=>{const scripts=[...index.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)];assert.ok(scripts.length>0);for(const m of scripts){if(m[1].trim())new vm.Script(m[1]);}});
check('Formulario de admisión: datos de contacto',()=>{for(const id of ['member-full-name','member-phone','membership-request-form'])assert.ok(index.includes('id="'+id+'"'),id)});
check('Admisión: envío y errores visibles',()=>{assert.match(index,/id="membership-request-form"[^>]*onsubmit="submitMembership\(event\)"[^>]*novalidate/);assert.match(index,/async function submitMembership\(ev\)/);assert.match(index,/form\.checkValidity\(\)/);assert.match(index,/membershipFeedback\('Revisá el campo/);assert.match(index,/authClient\.rpc\('submit_membership_request'/);assert.match(index,/membership-submit-feedback" role="alert"/);assert.ok(!index.includes("saveMembershipConfiguration(false)"));});
check('Consultas privadas y bandejas',()=>{for(const id of ['lawyer-inquiry-inbox','my-client-inquiries','inquiry-filter','account-notification-feed'])assert.ok(index.includes(id),id);for(const fn of ['openClientInquiry','openClientInquiryChat','loadClientInquiries'])assert.ok(index.includes('function '+fn+'('),fn)});
check('Lectura y seguimiento de mensajes',()=>{assert.ok(index.includes('client_inquiry_reads'));assert.ok(index.includes('markClientInquiryRead'));assert.ok(index.includes('client_inquiry_messages'))});
check('Preferencias de notificación sin prometer activación',()=>{assert.ok(index.includes('member_notification_preferences'));assert.ok(index.includes('próximamente'));assert.ok(index.includes('saveNotificationPreferences'))});
check('Conexión Talento',()=>{for(const id of ['talent-lawyer','talent-student','talent-filter-province','talent-filter-interest'])assert.ok(index.includes(id),id);assert.ok(index.includes('filterTalentCards'))});
check('Accesibilidad básica',()=>{assert.ok(index.includes('role="status"'));assert.ok(index.includes('aria-live'));assert.ok(index.includes('showStudioHelp'))});
check('PWA',()=>{const sw=fs.readFileSync('sw.js','utf8');const manifest=JSON.parse(fs.readFileSync('manifest.webmanifest','utf8'));assert.equal(manifest.name,'Estudio 3.14');assert.ok(sw.includes('fetch'));assert.ok(index.includes('manifest.webmanifest'))});
check('Páginas públicas de membresías',()=>{for(const file of ['plan-acceso.html','plan-crecimiento.html']){const html=fs.readFileSync(file,'utf8');assert.match(html,/<!doctype html>/i);assert.ok(html.length>5000)}});
const failures=cases.filter(x=>!x.ok);console.log('\nAuditoría: '+(cases.length-failures.length)+'/'+cases.length+' pruebas superadas');if(failures.length)process.exitCode=1;
