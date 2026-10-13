# MEMORY.md — Memoria del proyecto

> Estado vivo de **Fisioterapia Online con Adela**. Lo actualiza el agente o el equipo al final de cada sesión.
> Reglas de trabajo en [`AGENTS.md`](AGENTS.md). Qué se construye, en [`specs/`](specs/).

---

## Estado actual

| Campo | Valor |
|---|---|
| Fase | **Arranque del proyecto**: demo aceptada por la clienta; revisión de brief y stack en curso |
| Cliente | Adela Alventosa, fisioterapeuta colegiada |
| Responsable | José Miguel (Altera Soluciones Tecnológicas) |
| Prototipo | https://devai82.github.io/adela-fisioterapia/ |
| Demo comercial | https://devai82.github.io/demos-comerciales/adela-fisio/ |
| Financiación | Bono Crecimiento Pyme JCCM (pendiente de confirmar para este cliente) |

## Decisiones

Formato: fecha · decisión · motivo · alternativas descartadas.

| # | Fecha | Decisión | Motivo |
|---|---|---|---|
| D-001 | 2026-10-13 | Se sigue adelante con el servicio partiendo de la demo | La clienta la aprueba en la reunión del 13/10 |
| D-002 | 2026-10-13 | Marca oficial: logo **"Fisioterapia Online con Adela"** aportado por la clienta. Sustituye a la propuesta "ADELA Fisioterapia" en verde salvia | Lo aporta la clienta |
| D-003 | 2026-10-13 | Paleta extraída del logo: verde `#3C923A`, azul `#077AB9` / `#056F9C`, celeste `#139CD8`, amarillo `#FDCC1C` | Coherencia con la marca. Tokens en `AGENTS.md §4` |
| D-004 | 2026-10-13 | Metodología SDD con `AGENTS.md`, `MEMORY.md` y `specs/` | Base sólida y trazable desde el inicio |
| D-005 | 2026-10-13 | Secretos solo en `.env` (gitignored) y en el gestor de secretos del proveedor; `.env.example` como plantilla | El repo es público (GitHub Pages) |
| D-006 | 2026-10-13 | **Sin recepcionista ni contestador con IA. ElevenLabs queda fuera** por ahora | Decisión de Adela: prefiere atender todo por escrito |
| D-007 | 2026-10-13 | El teléfono **nunca se atiende**: todas las llamadas escuchan un mensaje fijo que deriva a WhatsApp (mismo número), email o web, sin buzón de voz | Decisión de Adela. Spec `features/001-atencion-telefonica.md` |

## Pendiente de decidir / validar con José Miguel

- [ ] **Brief definitivo** tras la reunión del 13/10 → `specs/00-brief.md`
- [ ] **Stack definitivo** → `specs/01-stack.md` (hosting, backend, pagos, dominio)
- [ ] Alcance de la fase 1 (MVP) frente a fases posteriores
- [ ] **Línea móvil de la clínica**: pendiente de alta; operador por decidir (spec 001)
- [ ] **WhatsApp Business** en ese mismo número: pendiente de contratar. Verificarlo *antes* de activar el desvío de llamadas
- [ ] **Email profesional** de la clínica (va en el mensaje telefónico)
- [ ] Datos reales de la clínica: nº de colegiada, horarios, tarifas
- [ ] Dominio propio
- [ ] Textos legales: aviso legal, privacidad, consentimiento sanitario, cookies
- [ ] ¿Se actualiza `presentacion.html` (dossier) con la nueva marca o queda como histórico?

## Riesgos conocidos

| Riesgo | Mitigación |
|---|---|
| Datos de salud (RGPD art. 9) | RLS, servidores en la UE, contratos de encargado del tratamiento, consentimiento explícito |
| Dependencia de terceros (Zernio) | Abstraer integraciones; plan B documentado en el stack |
| El operador no permite desactivar el buzón de voz | Centralita virtual "mensaje y colgar" (spec 001, opción B) |
| El prototipo usa Tailwind por CDN (no apto para producción) | Build propio en el stack definitivo |

## Glosario

- **EVA**: Escala Visual Analógica del dolor (0–10).
- **Lead**: persona interesada que aún no es paciente.
- **RLS**: Row Level Security de Postgres/Supabase.
- **Zernio**: plataforma omnicanal de WhatsApp e Instagram.

## Registro de sesiones

### 2026-10-13
- Reunión con Adela: le gusta la demo y se sigue adelante.
- Integrado el logo oficial y su paleta en el prototipo (web, CRM, portal, teléfono, favicon, imagen Open Graph).
- Creada la base SDD: `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `.env.example`, `.gitignore` y `specs/`.
- Decisión: sin recepcionista IA (D-006); el teléfono siempre reproduce un mensaje y deriva a WhatsApp, email o web (D-007).
- Prototipo: la pestaña "Voz IA 24/7 (ElevenLabs)" pasa a ser "Teléfono → WhatsApp" con el nuevo flujo; eliminado todo el código de ElevenLabs. Corregido el desbordamiento de la barra de pestañas en móvil.
- Spec `001-atencion-telefonica` creada (implementación bloqueada por el alta de la línea).
- **Siguiente paso:** repasar con José Miguel el resto del brief y el stack, y aprobar ambos.
