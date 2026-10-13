# 01 · Stack tecnológico y arquitectura

| Campo | Valor |
|---|---|
| Estado | `borrador`: **pendiente de revisar con José Miguel** |
| Fuente | Dossier inicial ("despliegue del VPS y Supabase") y demo |
| Última actualización | 2026-10-13 |

> ⚠️ Este borrador refleja lo que se planteó en la propuesta. Cada fila tiene una columna
> **Decisión** para dejarla en ✅ (confirmada), 🔄 (cambia) o ❌ (se descarta) en la revisión.

---

## 1. Componentes

| Capa | Propuesta inicial | Alternativas a valorar | Decisión |
|---|---|---|---|
| Frontend web y portal | ❓ (el prototipo es un HTML con Tailwind por CDN) | Astro, Next.js, SvelteKit, React + Vite | ❓ |
| Estilos | Tailwind CSS (con build, no CDN) | — | ❓ |
| Backend / BBDD / Auth | **Supabase** (Postgres + Auth + RLS + Storage + Edge Functions) | Supabase autoalojado en VPS | ❓ |
| Hosting | **VPS** | Vercel / Netlify (frontend) + Supabase Cloud (región UE) | ❓ |
| Vídeos de ejercicios | Supabase Storage | Bunny Stream, Vimeo privado, YouTube oculto | ❓ |
| Mensajería omnicanal | **Zernio** (WhatsApp + Instagram) | WhatsApp Cloud API directa | ❓ |
| Telefonía | Línea móvil de la clínica con desvío incondicional a un mensaje fijo (operador pendiente) | Centralita virtual "mensaje y colgar" | ✅ Mensaje fijo, sin IA (D-006). Operador ❓ |
| Voz IA | ~~ElevenLabs Conversational AI ("Sofía")~~ | — | ❌ Fuera por ahora (D-006) |
| Agenda y videoconsulta | **Google Calendar + Google Meet** | Cal.com + Meet/Jitsi | ❓ |
| Email transaccional | Resend | Brevo, SMTP de Google Workspace | ❓ |
| Pagos | ❓ | Stripe (suscripciones), Bizum vía TPV | ❓ |
| Analítica web | ❓ | Plausible / Umami (sin cookies) | ❓ |
| Repositorio y CI | GitHub (`DevAI82/adela-fisioterapia`) + GitHub Actions | — | ❓ |

## 2. Arquitectura (borrador)

```
   Paciente (web/móvil)          Adela (panel)              Canales externos
          │                           │                 WhatsApp · Instagram · Email
          │                           │            (Teléfono → mensaje fijo → WhatsApp/web)
          ▼                           ▼                         │
   ┌─────────────────────────────────────────┐          ┌──────┴──────┐
   │  Frontend (web pública + portal + CRM)  │          │ Zernio/Email │
   └───────────────────┬─────────────────────┘          └──────┬──────┘
                       │  supabase-js (anon key + RLS)          │ webhooks
                       ▼                                        ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ Supabase (UE): Postgres + Auth + Storage + Edge Functions       │
   │   RLS: paciente ve solo lo suyo · notas clínicas solo Adela     │
   └───────────────────────────┬─────────────────────────────────────┘
                               ▼
                 Google Calendar/Meet · Email · Pagos
```

## 3. Modelo de datos inicial (borrador)

| Tabla | Contenido | Acceso |
|---|---|---|
| `profiles` | Usuario (rol: `fisio` / `paciente`) | Cada uno el suyo; la fisio, todos |
| `leads` | Contacto, canal de origen, estado del tablero | Solo la fisio |
| `consents` | Consentimientos RGPD con fecha, versión del texto e IP | Solo inserción; lectura por la fisio |
| `questionnaires` | Respuestas del cuestionario clínico | Paciente (las suyas) y fisio |
| `clinical_notes` | Notas privadas de Adela | **Solo la fisio** |
| `routines`, `exercises` | Planes y ejercicios con vídeo | Paciente (los asignados) y fisio |
| `pain_logs` | Registro diario de EVA y adherencia | Paciente (los suyos) y fisio |
| `appointments` | Citas y enlaces de Meet | Paciente (las suyas) y fisio |
| `messages` | Conversaciones omnicanal | Fisio; paciente solo las del portal |

## 4. Requisitos no funcionales

- **Ubicación de datos:** UE (Supabase región Frankfurt, VPS en la UE).
- **Seguridad:** RLS en todas las tablas, 2FA para la cuenta de Adela, copias de seguridad diarias.
- **Rendimiento:** web pública con Lighthouse ≥ 90 en móvil.
- **Accesibilidad:** WCAG 2.1 AA.
- **Entornos:** `local` → `staging` → `producción`, cada uno con su `.env`.

## 5. Variables de entorno

Ver [`.env.example`](../.env.example). Se ajusta cuando este documento quede aprobado.

## 6. Preguntas abiertas para la revisión

1. ¿VPS propio o servicios gestionados? (coste, mantenimiento, RGPD)
2. ¿Qué framework de frontend usamos?
3. ¿Se mantiene Zernio o vamos a la API oficial de WhatsApp? (Ojo: el número de WhatsApp será el del móvil de la clínica; ver spec 001 §7.)
4. ¿Operador de la línea móvil? (pendiente de alta)
5. ¿Pasarela de pago?
6. ¿El prototipo de GitHub Pages se mantiene como demo o lo sustituye la web real?
