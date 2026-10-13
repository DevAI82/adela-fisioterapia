# 02 · Plan del proyecto

| Campo | Valor |
|---|---|
| Estado | `borrador`: **pendiente de aprobación de José Miguel** |
| Basado en | `00-brief.md` (13/10/2026) y `01-stack.md` |
| Última actualización | 2026-10-13 |

Cada fila de las fases es **una spec** en `specs/features/`. Se escribe, se aprueba, se implementa y se verifica en ese orden (ver `AGENTS.md §2`). Las fechas se fijarán cuando estén claros los plazos (pendiente: SL y JCCM).

---

## Fase 0 · Validación y cimientos

Objetivo: que Adela valide el producto con el prototipo antes de construir, y dejar lista la infraestructura.

| Spec | Qué | Depende de |
|---|---|---|
| **002-prototipo-v2** ✅ hecha (13/10, pendiente de validar con Adela) | Actualizar el prototipo con lo acordado: Quiénes somos, servicios destacados, oferta de la 1ª consulta, paso de "tipo de problema" y adjuntos en el cuestionario, biblioteca de vídeos y prescripción con series/repeticiones/frecuencia/duración, mini cuestionario de la sesión, **historial del paciente**, pagos y enlaces de pago. Sirve de **especificación visual** para Adela | — |
| 003-stack-definitivo | Cerrar `01-stack.md`: framework de frontend, videollamada, email transaccional y proveedor del VPS | — |
| 004-infraestructura | VPS en Francia, Coolify, Supabase autoalojado, dominio, TLS, copias de seguridad cifradas, entornos de staging y producción, CI | 003 · dominio |
| 005-modelo-datos-y-seguridad | Esquema de base de datos, políticas RLS, buckets privados, 2FA de Adela, registro de accesos, consentimientos versionados | 004 |

## Fase 1 · MVP: captar, cobrar y atender (salida a producción)

| Spec | Qué | Depende de |
|---|---|---|
| 006-web-publica | Landing con la marca, Quiénes somos, servicios destacados, tarifas con la oferta y textos legales | 002 · textos de Adela |
| 007-cuestionario-y-registro | Cuestionario clínico con tipo de problema y zona, comentarios, **adjuntos médicos**, consentimientos y alta de cuenta | 005 |
| 008-pagos-stripe | Primera consulta 22,50 € (Bizum/tarjeta), sesión suelta, suscripciones con tarjeta, **enlace de pago desde el CRM** y registro de pagos | 005 · cuenta de Stripe |
| 009-agenda-y-reservas | Disponibilidad editable, duraciones de 25 y 45 min + 15 min de descanso, reserva solo tras pagar, reagendar sin coste, enlace de videollamada | 008 · cuenta de Google |
| 010-ficha-e-historial | **Historial del paciente**: línea temporal con cuestionario, adjuntos, consultas (notas privadas y resumen para el paciente), pagos y mensajes | 007 · 008 |
| 001-atencion-telefonica | Mensaje fijo y derivación (ya especificada) | Alta de la línea |

## Fase 2 · Tratamiento online

| Spec | Qué | Depende de |
|---|---|---|
| 011-biblioteca-videos-voces | Subida desde el panel a Cloudflare R2 (genéricos) y a Supabase (personalizados), clasificación y búsqueda, reproducción del vídeo con la voz en off encima | 004 · vídeos de Adela |
| 012-prescripcion-rutinas | Montar rutinas desde la biblioteca con series, repeticiones, frecuencia, duración y nota | 011 · 010 |
| 013-portal-paciente | Rutina del día, botón "Ejercicio finalizado", **mini cuestionario de la sesión** (rigidez, EVA, estabilidad y comentario), citas y pagos | 012 |
| 014-whatsapp-zernio | Conversaciones de WhatsApp en el historial y en la bandeja de Adela | 010 · WhatsApp Business |

## Fase 3 · Mejora continua (posterior)

- Informes y KPIs (embudo, ingresos por plan, evolución clínica).
- Gráficas de evolución de dolor, rigidez y estabilidad en la ficha y en el portal.
- Recordatorios automáticos de citas y de rutinas.
- Integración de la facturación (VeriFactu) si se decide.
- Retomar la voz IA si Adela lo pide (D-006).

## Dependencias externas (bloqueantes)

| Qué | Responsable | Bloquea |
|---|---|---|
| Datos y foto para "Quiénes somos" | Adela | 006 |
| Dominio y email profesional | Adela / José Miguel | 004, 001 |
| Cuenta de Google | Adela | 009 |
| Cuenta de Stripe (titular: Adela) | Adela | 008 |
| Línea móvil + WhatsApp Business | Adela | 001, 014 |
| Vídeos y voces en off | Adela | 011 |
| Revisión RGPD y textos legales | Consultor RGPD / José Miguel | Salida a producción |
| Constitución de la SL y JCCM | José Miguel | Presentación de la subvención |

## Primer paso propuesto

**Spec 002 (prototipo v2).** No necesita ningún dato pendiente (lo que falte se muestra como ejemplo), permite a Adela validar el flujo completo antes de invertir en desarrollo y sirve de material visual para la memoria de la JCCM.
