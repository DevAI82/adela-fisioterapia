# 002 · Prototipo v2 (especificación visual del brief del 13/10)

| Campo | Valor |
|---|---|
| Estado | `hecha` (pendiente de validación por Adela) |
| Módulo | Transversal: M1, M2, M3, M6 y M8 |
| Prioridad | Alta (primer paso del plan) |
| Aprobada por | José Miguel (2026-10-13: "adelante con el prototipo v2") |
| Fecha | 2026-10-13 |

## 1. Contexto y objetivo
Llevar al prototipo interactivo (`index.html`) todo lo acordado con Adela en `00-brief.md`, para que **lo valide antes de desarrollar** y como material visual para la memoria de la JCCM.
Es un **prototipo**: los datos son ficticios, no hay backend, y pagos, subidas y reservas se simulan en el navegador.

## 2. Historias de usuario
- Como **visitante**, quiero conocer a Adela y sus servicios para confiar en un tratamiento online.
- Como **paciente nuevo**, quiero contar mi problema, adjuntar mis informes, pagar la primera consulta con descuento y reservar hora.
- Como **Adela**, quiero ver el historial completo de cada paciente, prescribir rutinas desde mi biblioteca de vídeos y voces, y enviar enlaces de pago.
- Como **paciente en tratamiento**, quiero hacer mi rutina, marcarla como finalizada y contarle a Adela cómo me he sentido.

## 3. Criterios de aceptación

### Web pública
- [x] **CA-1:** Hay una sección **"Servicios destacados"** (`#especialidades`) con 5 tarjetas: suelo pélvico, linfedema, prevención del envejecimiento (atrofia), lesiones deportivas y lesiones múltiples. Cada una tiene un texto breve y un botón que abre el cuestionario con ese tipo de problema preseleccionado.
- [x] **CA-2:** Hay una sección **"Quiénes somos"** (`#sobre-mi`) con la presentación de Adela. Los datos pendientes (formación, nº de colegiada, foto real) se marcan visiblemente como pendientes.
- [x] **CA-3:** En tarifas aparece la **Primera consulta** con ~~45 €~~ **22,50 €** y 25 min, indicando que es obligatoria y que admite Bizum o tarjeta. Los planes mensuales indican "suscripción con tarjeta".
- [x] **CA-4:** Los enlaces del menú (Servicios, Sobre nosotros) llevan a sus secciones.

### Alta del paciente
- [x] **CA-5:** El cuestionario empieza con el paso **"Tipo de problema"** (6 opciones). La zona de la silueta solo se pide si es dolor localizado.
- [x] **CA-6:** El cuestionario incluye **comentarios adicionales** y la **subida de informes médicos** (simulada, con aviso de privacidad), además del consentimiento RGPD.
- [x] **CA-7:** Al terminar, el paciente **se registra** (nombre, email, teléfono, contraseña) y pasa al **pago de la primera consulta** (22,50 €) eligiendo **Bizum o tarjeta** en un checkout simulado de Stripe.
- [x] **CA-8:** Solo tras pagar se abre la **reserva**: martes y jueves de 16:00 a 20:00, con huecos de 25 min (primera consulta) o 45 min (sesión) más 15 min de descanso. Al confirmar, se pasa al portal.

### Panel de Adela (CRM)
- [x] **CA-9:** Nueva sección **"Pacientes · Historial"**: lista de pacientes y, al elegir uno, su **línea temporal** con el cuestionario inicial y los adjuntos, las consultas (notas privadas 🔒 y resumen enviado al paciente), las rutinas prescritas, las sesiones con su mini cuestionario y comentario, las respuestas de Adela, los mensajes de WhatsApp y los **pagos**. Incluye filtros por tipo de evento.
- [x] **CA-10:** Desde la ficha, Adela puede **añadir una nota de consulta** (privada y resumen para el paciente), **responder** a un comentario del paciente y **enviar un enlace de pago** de un plan o sesión.
- [x] **CA-11:** Nueva sección **"Biblioteca"** con los vídeos y las voces en off por separado, etiquetas (dolencia o zona), buscador y filtro, y la **subida simulada** de vídeo o audio.
- [x] **CA-12:** Nueva sección **"Prescribir rutina"**: Adela elige ejercicios de la biblioteca y, para cada uno, la voz en off, **series, repeticiones, frecuencia y duración** (desplegables) y una nota. Al enviar, la rutina aparece en el historial del paciente.
- [x] **CA-13:** Nueva sección **"Agenda"** con la disponibilidad (martes y jueves de 16:00 a 20:00), las citas de la semana con su estado de pago y la acción **"Reagendar sin coste"** para no presentados.

### Portal del paciente
- [x] **CA-14:** La rutina del día muestra cada ejercicio con su pauta (series, repeticiones, frecuencia, duración y nota de Adela) y un indicador de **voz en off**.
- [x] **CA-15:** Cada ejercicio tiene **"Ejercicio finalizado"**. Al completar todos (o al pulsar "Terminar sesión"), se abre el **mini cuestionario de la sesión**: rigidez (elevada, moderada, ligera o ninguna), dolor (EVA 0–10), estabilidad (alta, media o baja) y comentario libre.
- [x] **CA-16:** Al enviar el mini cuestionario aparece la confirmación "Adela lo verá en tu historial", y **el registro aparece en el historial del CRM** de ese paciente.
- [x] **CA-17:** El portal muestra el **resumen de la última consulta** enviado por Adela, el **plan activo** con la opción de cambiarlo o contratarlo (pago simulado) y las **próximas citas**.

### General
- [x] **CA-18:** Sin errores de JavaScript; usable a 390 px y a 1280 px; `mockup_interactivo.html` idéntico a `index.html`.
- [x] **CA-19:** Se usa solo la paleta de `AGENTS.md §4`; los datos de pacientes son ficticios.

## 4. Fuera de alcance
- Backend real, autenticación, Stripe real, almacenamiento real y videollamada real.
- Informes y KPIs (se mantienen los de la demo; fase 3).
- Rediseño del CRM para móvil: el panel de Adela se usa en ordenador.

## 5. Datos y privacidad
Solo datos ficticios. Las subidas de archivos no salen del navegador. Los textos de privacidad del prototipo son orientativos, no legales.

## 6. Diseño / UX
- Mantener el estilo actual del prototipo y la marca (D-002, D-003).
- Lo pendiente de Adela se muestra con la etiqueta amarilla "Pendiente" (`sun-100` / `sun-600`).

## 7. Plan técnico
- Todo en `index.html` (HTML + Tailwind CDN + JS vanilla), copiado después en `mockup_interactivo.html`.
- **Estado en memoria** (objeto JS `demoState`): pacientes, biblioteca, rutinas y eventos del historial. El mini cuestionario y las notas añaden eventos al historial y se ven al cambiar de vista.
- Nuevas subvistas del CRM conectadas al `switchCrmTab` existente: `historial`, `biblioteca`, `prescribir` y `agenda`.
- El flujo de alta reutiliza el cuestionario existente y añade pasos y modales: registro, checkout y reserva.

## 8. Tareas
- [x] T1 Web pública: servicios destacados, quiénes somos y tarifas.
- [x] T2 Cuestionario v2, registro, checkout y reserva.
- [x] T3 CRM: historial, biblioteca, prescripción, agenda y enlace de pago.
- [x] T4 Portal: rutina con pauta, ejercicio finalizado, mini cuestionario, resumen, plan y citas.
- [x] T5 Verificación con Playwright a 390 y 1280 px; capturas; MEMORY.

## 9. Verificación
Prueba de punta a punta automatizada con Playwright (Chromium) el 13/10/2026: **28/28 comprobaciones correctas, sin errores de JavaScript**.

Recorrido probado:
1. Web pública con 5 servicios, Quiénes somos y tarifas con la primera consulta a 22,50 € (CA-1 a CA-4).
2. Alta de una paciente nueva de suelo pélvico: paso de tipo de problema sin silueta, adjunto PDF, comentarios, registro y consentimientos (CA-5 a CA-7).
3. Pago con Bizum de la primera consulta, reserva entre 16:00 y 20:00 respetando los 15 min de descanso, y entrada al portal (CA-7, CA-8).
4. En el CRM, el historial de la paciente con cuestionario, adjunto, pago y cita; nota de consulta y enlace de pago (CA-9, CA-10).
5. Prescripción de 2 ejercicios con pauta y voz en off (CA-12).
6. En el portal, pago del enlace solo con tarjeta (suscripción), "Ejercicio finalizado" en los dos ejercicios, mini cuestionario y confirmación (CA-14 a CA-17).
7. La sesión aparece en el historial; Adela responde (CA-16).
8. Agenda de 4 días; un no presentado se reagenda sin coste (CA-13).
9. Biblioteca con 9 vídeos; subida simulada de una voz personalizada (CA-11).
10. A 390 px no hay scroll horizontal en la web, el portal ni el teléfono; `mockup_interactivo.html` es idéntico a `index.html` (CA-18).

Notas:
- El panel del CRM no está pensado para móvil (fuera de alcance).
- En el entorno de prueba el CDN de Tailwind está bloqueado; el CSS se generó en local con la misma configuración. En GitHub Pages se usa el CDN.
- La "voz en off" se simula con la voz del navegador; si se sube un audio real en la biblioteca, se reproduce ese audio.

## 10. Notas y decisiones
- Por instrucción del entorno de trabajo, se desarrolla en la rama `claude/amazing-davinci-culuiq` en lugar de `feat/002-prototipo-v2`.
- Instagram se elimina del prototipo (D-011): Isabel pasa a llegar por la web.
- El HTML original del CRM no cerraba el contenedor principal; las subvistas nuevas se insertan después de Informes, respetando esa estructura.
- Textos de servicios y "Quiénes somos" redactados por nosotros y marcados como borrador para que los revise Adela.
