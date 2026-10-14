# 003 · Stack definitivo

| Campo | Valor |
|---|---|
| Estado | `borrador`: **6 de 8 decisiones tomadas**; faltan frontend (1) y frecuencia de copias / analítica (5, 6) |
| Módulo | Transversal (infraestructura y arquitectura) |
| Prioridad | Alta: bloquea las specs 004 (infraestructura) y 005 (modelo de datos) |
| Aprobada por | — |
| Fecha | 2026-10-14 |

## 1. Contexto y objetivo
Cerrar las piezas del stack que siguen abiertas en `01-stack.md`, para empezar a construir la aplicación real.
Ya están decididos: VPS en Francia con Coolify y Supabase autoalojado (D-010), Stripe (D-009), WhatsApp vía Zernio (D-011) y Cloudflare R2 para los vídeos genéricos (D-012).

## 2. Decisiones (revisión con José Miguel, 14/10/2026)

| # | Decisión | Resultado | Notas |
|---|---|---|---|
| 1 | Frontend | 🔄 **Propuesta: Astro + Vue** (islas de Vue para el portal y el panel). **Pendiente del ok de José Miguel** | José Miguel prefiere Vue o Astro para una web más premium y con efectos. Astro sirve la web pública muy rápida y bien posicionada (SEO), con transiciones entre páginas; Vue da la interactividad del portal y el panel. Alternativa: Nuxt (Vue completo) |
| 2 | Proveedor del VPS | ✅ **Contabo**, centro de datos en Francia (Lauterbourg) | José Miguel ya lo conoce. Firmar el contrato de encargado del tratamiento (AVV) de Contabo. Plan de 8 GB de RAM o más para Supabase |
| 3 | Videollamada | ✅ **Google Meet** | Pendiente de que Adela cree su cuenta de Google. Recomendado Google Workspace (incluye contrato de protección de datos y email con su dominio) |
| 4 | Email transaccional | ✅ **Resend, plan gratuito** | Límite: 100 emails/día y 3.000/mes. Los emails no llevarán datos de salud (solo avisos y enlaces al portal). Revisar el contrato de encargado del tratamiento de Resend |
| 5 | Copias de seguridad | ✅ **Copias programadas de Coolify** sobre Supabase autoalojado. **Pendiente: frecuencia** | Propuesta: **diaria** en vez de semanal (con copia semanal se podría perder hasta una semana de notas clínicas), enviada fuera del VPS a almacenamiento compatible con S3 en la UE, y **copia también de los ficheros** (informes adjuntos). Verificar en la spec 004 cómo hace Coolify la copia del Postgres dentro del servicio Supabase y probar una restauración |
| 6 | Analítica web | ❓ **Umami**, pendiente de decidir | Explicado a José Miguel: alternativa a Google Analytics, gratuita y sin cookies |
| 7 | Facturación | ✅ **Fuera de la fase 1** | Funcionalidad futura. El CRM registra los pagos de Stripe; la gestoría factura |
| 8 | Calidad | ✅ **Revisión con skills de frontend, SEO y seguridad** antes de cada entrega | Se recomienda mantener además los tests automáticos de RLS (privacidad de los datos clínicos) |

## 3. Arquitectura resultante

```
                     Coolify en VPS Contabo (Francia)
 ┌─────────────────────────────────────────────────────────────────┐
 │  App Astro + Vue (web pública · portal · panel de Adela)        │
 │        │  Supabase SSR (sesión con cookies, RLS)                 │
 │  Supabase: Postgres · Auth · Storage privado · Edge Functions   │
 │  Umami (analítica sin cookies) · pendiente de decidir          │
 └──────┬──────────────┬───────────────┬──────────────┬────────────┘
        │              │               │              │
   Stripe (pagos)  Zernio (WhatsApp)  Google Meet      Cloudflare R2
   webhooks        webhooks          + Calendar        vídeos genéricos
   Resend (emails transaccionales)                     (URLs firmadas)
 Copias programadas de Coolify (BD + ficheros) → almacenamiento S3 en la UE
```

## 4. Criterios de aceptación
- [ ] **CA-1:** Cada fila de §2 tiene una decisión (✅, 🔄 con la alternativa elegida, o ❌).
- [ ] **CA-2:** Todos los proveedores con datos personales están en la UE o tienen contrato de encargado del tratamiento.
- [ ] **CA-3:** `01-stack.md` refleja lo decidido; `.env.example` tiene solo las variables necesarias.
- [ ] **CA-4:** `AGENTS.md §3` incluye la estructura de carpetas de la aplicación.
- [ ] **CA-5:** Las decisiones quedan registradas en `MEMORY.md`.

## 5. Fuera de alcance
Instalar o contratar nada: eso es la spec 004 (infraestructura).

## 6. Coste orientativo mensual (a confirmar con precios actuales)
VPS de 8 GB en Francia, Google Workspace Business Starter (1 usuario), dominio, Stripe (comisión por cobro), Zernio (plan gratuito) y R2 (gratis hasta 10 GB). Lo detallaremos con precios reales al aprobar la spec.

## 7. Plan técnico
Una vez aprobada:
1. Actualizar `01-stack.md`, `.env.example` y `AGENTS.md §3`.
2. Escribir la spec 004 (infraestructura) y la 005 (modelo de datos y seguridad).

## 8. Tareas
- [ ] T1 Revisión con José Miguel fila a fila.
- [ ] T2 Actualizar la documentación (CA-3, CA-4 y CA-5).

## 9. Verificación
_(se rellena al aprobar)_

## 10. Notas y decisiones
- 2026-10-14: propuesta extraída de `01-stack.md §7` a esta spec, a petición de José Miguel.
- 2026-10-14: revisión fila a fila con José Miguel (tabla de §2).
