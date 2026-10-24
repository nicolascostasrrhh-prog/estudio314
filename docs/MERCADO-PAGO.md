# Créditos y Mercado Pago — arquitectura y activación

## Modelo comercial definido
Los créditos se **compran** a través de Mercado Pago. No existe una aprobación administrativa para acreditar cada compra. Una vez que Mercado Pago confirma un pago elegible, el servidor acredita el paquete y el profesional puede solicitar servicios utilizando ese saldo. La admisión profesional a Estudio 3.14 sigue siendo un proceso independiente de la compra de créditos.

## Implementado
- Tabla `credit_packages`: nombre, cantidad de créditos, importe en ARS, habilitación; sin paquetes, precios ni valores inventados.
- Tabla `credit_checkout_intents`: identifica un checkout por usuario, paquete y precio congelado al iniciarlo.
- Tabla `credit_purchase_receipts`: comprobante y unicidad del pago externo.
- Función `credit_verified_checkout_intent` restringida a `service_role`, con bloqueo de la intención, acreditación atómica y prevención de duplicados de webhook. No puede ejecutarla una sesión de usuario.
- Edge Function `create-credit-checkout` (JWT obligatorio): autentica al miembro, comprueba la verificación profesional y el paquete activo, crea la intención y solicita un enlace de Checkout Pro a Mercado Pago.
- Edge Function `mercadopago-credit-webhook` (sin JWT porque la llama Mercado Pago): exige firma HMAC válida, consulta el pago desde la API de Mercado Pago, exige estado aprobado, ARS, importe esperado, preferencia e intención correctas. Solo entonces invoca la acreditación.
- Interfaz de **Mi cuenta → Comprar créditos**: saldo, paquetes habilitados, acceso al enlace, compras confirmadas. Sin paquetes activos muestra “No disponible”.
- El retorno a la web **no acredita** créditos; la única fuente de verdad es el webhook verificado.

## Pendiente antes de cobrar
1. Identificar y configurar una cuenta Mercado Pago comercial válida. Guardar su `MERCADOPAGO_ACCESS_TOKEN` **exclusivamente como secreto de Supabase Edge Functions**; nunca agregarlo a GitHub, `index.html`, `config.js` ni compartirlo en chats.
2. Configurar y guardar el `MERCADOPAGO_WEBHOOK_SECRET`, seleccionar evento **Payments** y registrar `https://pdefftaresvglcugzqtz.supabase.co/functions/v1/mercadopago-credit-webhook`.
3. Aprobar paquetes comerciales concretos: nombre, cantidad de créditos y precio final en ARS. Cargarlos primero inactivos, ensayar, y habilitarlos después de probar.
4. Hacer pagos de prueba y verificar acreditación única, repetición de notificación, rechazo, importe incorrecto, precio modificado durante el checkout, errores de conexión, devoluciones y contracargos.
5. Definir políticas de facturación, caducidad, reintegros, impuestos y protección de datos. **Actualmente no se revierten automáticamente créditos por chargebacks o devoluciones de Mercado Pago.**
6. Verificar en entorno real el comportamiento de Checkout Pro, correos y URL de regreso; las funciones figuran desplegadas, pero no se probó una transacción monetaria.

## Importante
No usar un **link de pago genérico** para acreditar automáticamente una cuenta: sin una referencia individual verificada no es seguro atribuir el pago al profesional que compró. El checkout crea un enlace individual con referencia a la compra; cuando se valide la identidad del cobro podrá acreditarse sin intervención humana.

Fuentes: documentación oficial Mercado Pago Checkout Pro Preferences y Webhooks.
