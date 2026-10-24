# Publicación de posts y reels con Metricool — diseño operativo

**Estado:** servicio visible en el prototipo de Estudio 3.14; no hay una cuenta Metricool conectada ni publicaciones automáticas desde el panel.

## Servicios propuestos (créditos ilustrativos, pendientes de costeo)

| Servicio | Alcance | Créditos de prueba |
|---|---|---:|
| Contenido visual para historias y feed | Hasta 4 creatividades estáticas, sin programación | 5 |
| Video o reel para redes | Un video vertical de hasta 30 segundos, sin programación | 8 |
| Programación y publicación | Hasta 4 posts/reels terminados, en hasta 2 redes de una marca | 4 |
| Contenido y publicación | Hasta 4 creatividades estáticas más programación/publicación | 9 |

El planificador no debe publicar nada que no esté aprobado por el abogado. La gestión de mensajes/comentarios, anuncios pagos y creación de videos se contratan aparte.

## Arquitectura

- Un estudio jurídico/abogado autorizado corresponde a una **marca** de Metricool si utiliza un perfil por red social.
- Una marca puede agrupar sus propias conexiones (p. ej., Instagram y Facebook). Si un cliente tiene varias cuentas de la misma red, requerirá marcas adicionales.
- Administradores/operadores de Estudio 3.14 se ocupan de conectar y programar con permisos. No se deben solicitar ni almacenar contraseñas de redes sociales.
- Autorización del titular y aprobación registrada por publicación, antes de programar, con texto, fecha, medios y plataforma.
- Un pedido genera tareas operativas: pendiente de material → pendiente de aprobación → aprobado → programado → publicado/error.
- Guardar evidencia: enlace del post, fecha/hora, plataforma, estado, errores y persona operadora.
- Cambios después de aprobar: exigir nueva aprobación si se altera sustancialmente el contenido.
- Evitar colocar datos de clientes, expedientes o situaciones jurídicas identificables sin base legítima y autorización.

## Límites y decisiones pendientes

Según el centro de ayuda oficial de Metricool consultado en octubre de 2026, los planes disponibles permiten distintas cantidades de marcas: Free 1; Starter 5/10; Advanced 15/25/50; Custom desde 50. La disponibilidad exacta y precio deben verificarse antes de contratar.

La colaboración por marca, roles y flujos de aprobación están disponibles en planes Advanced/Custom. La API programática corresponde a esos planes. **No se ha comprado plan, ni conectado cuenta ni probado API.**

Fuentes:
- https://help.metricool.com/es/principales-diferencias-entre-los-planes-free-y-de-pago-bl0v9
- https://help.metricool.com/es/marcas-compartidas-en-metricool-uf4oz
- https://help.metricool.com/plans-add-ons-and-api-access-explained-xux1u
- https://help.metricool.com/es/opciones-de-programacion-y-publicacion-por-red-social-cwmb3

## Futuro módulo de aprobación

1. El abogado carga materiales y define redes, fecha/hora y objetivo.
2. Estudio 3.14 arma previsualización.
3. El titular aprueba explícitamente cada versión.
4. Un trabajador autorizado programa mediante Metricool.
5. Sistema recupera o registra resultados de publicación y los expone en el panel.
6. Se aplican créditos solo según términos aceptados y estados efectivos del pedido.

**Comercial:** evaluar si el costo se expresa por post, por marca, por número de redes y/o un abono mensual. Los créditos del prototipo son valores demostrativos, no precios vigentes.
