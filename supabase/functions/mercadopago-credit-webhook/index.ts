import {createClient} from "https://esm.sh/@supabase/supabase-js@2";
const respond=(message:string,status=200)=>new Response(JSON.stringify({message}),{status,headers:{"Content-Type":"application/json"}});
function equalHex(a:string,b:string){if(a.length!==b.length)return false;let v=0;for(let i=0;i<a.length;i++)v|=a.charCodeAt(i)^b.charCodeAt(i);return v===0}
async function validSignature(req:Request,id:string,secret:string){
 const raw=req.headers.get("x-signature")||"";
 const fields=Object.fromEntries(raw.split(",").map(x=>x.trim().split("=")));
 const ts=fields.ts||"",hash=fields.v1||"",requestId=req.headers.get("x-request-id")||"";
 if(!/^\d{10,16}$/.test(ts)||!(/^[0-9a-f]{64}$/i).test(hash)||!requestId)return false;
 if(Math.abs(Date.now()-Number(ts))>15*60*1000)return false;
 const manifest="id:"+id+";request-id:"+requestId+";ts:"+ts+";";
 const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(secret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);
 const signature=new Uint8Array(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(manifest)));
 const hex=[...signature].map(b=>b.toString(16).padStart(2,"0")).join("");
 return equalHex(hex,hash.toLowerCase());
}
Deno.serve(async(req)=>{
 if(req.method!=="POST")return respond("Método no permitido",405);
 const secret=Deno.env.get("MERCADOPAGO_WEBHOOK_SECRET"),token=Deno.env.get("MERCADOPAGO_ACCESS_TOKEN");
 const supaUrl=Deno.env.get("SUPABASE_URL"),serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
 if(!secret||!token||!supaUrl||!serviceKey)return respond("Integración pendiente",503);
 const url=new URL(req.url);
 const dataId=url.searchParams.get("data.id")||url.searchParams.get("id")||"";
 if(!/^\d{1,30}$/.test(dataId)||!(await validSignature(req,dataId,secret)))return respond("Firma inválida",401);
 const mp=await fetch("https://api.mercadopago.com/v1/payments/"+encodeURIComponent(dataId),{headers:{Authorization:"Bearer "+token}});
 if(!mp.ok)return respond("No se pudo consultar pago en MP",502);
 const payment=await mp.json();
 if(String(payment.id)!==dataId)return respond("Pago inconsistente",400);
 if(payment.status!=="approved")return respond("Estado no acreditable");
 if(payment.currency_id!=="ARS"||!Number.isInteger(payment.transaction_amount)||payment.transaction_amount<=0)return respond("Importe inválido",400);
 const intentId=payment.external_reference;
 if(typeof intentId!=="string"||!(/^[0-9a-f-]{36}$/i).test(intentId))return respond("Referencia inválida",400);
 const sb=createClient(supaUrl,serviceKey);
 const {data:intent,error}=await sb.from("credit_checkout_intents").select("id,member_id,package_id,expected_amount_ars,expected_credits,provider_preference_id,status,payment_id").eq("id",intentId).maybeSingle();
 if(error||!intent)return respond("Compra no encontrada",404);
 if(intent.expected_amount_ars!==payment.transaction_amount)return respond("Monto distinto",400);
 if(intent.provider_preference_id&&String(payment.preference_id||"")!==String(intent.provider_preference_id))return respond("Preferencia distinta",400);
 if(intent.status==="credited")return respond(intent.payment_id===dataId?"Compra ya acreditada":"Conflicto de pago",intent.payment_id===dataId?200:409);
 const {data:receipt,error:creditError}=await sb.rpc("credit_verified_mercadopago_payment",{p_payment_id:dataId,p_member:intent.member_id,p_package:intent.package_id,p_amount_ars:intent.expected_amount_ars});
 if(creditError||!receipt)return respond("Acreditación no confirmada",500);
 const updated=await sb.from("credit_checkout_intents").update({status:"credited",payment_id:dataId,credited_at:new Date().toISOString()}).eq("id",intent.id).eq("status","pending");
 if(updated.error)return respond("Pago acreditado, sincronización pendiente",500);
 return respond("Créditos acreditados");
});