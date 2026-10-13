# 00 · Brief del proyecto

| Campo | Valor |
|---|---|
| Estado | `borrador` **listo para aprobar**: recoge lo acordado con Adela el 13/10/2026 |
| Fuente | Reunión con la clienta (13/10/2026), demo y conversación con José Miguel |
| Última actualización | 2026-10-13 |

> Leyenda: ❓ = pendiente de dato o decisión. Lo marcado como **[supuesto]** es una interpretación nuestra a confirmar.

---

## 1. Cliente y negocio

- **Clienta:** Adela Alventosa, fisioterapeuta colegiada (nº de colegiada, colegio y formación ❓, pendientes para "Quiénes somos").
- **Marca:** "Fisioterapia Online con Adela" (logo y paleta oficiales: D-002 y D-003).
- **Modelo:** fisioterapia **100 % online**. Sin consulta presencial.
- **Canales de contacto:** **WhatsApp** (mismo número que el teléfono) y **la web**, además del email. Sin Instagram ni LinkedIn por ahora.
- **Teléfono:** nunca se atiende; mensaje fijo que deriva a WhatsApp, email o web (D-007, spec 001).
- **Público objetivo:** ❓

## 2. Problema que resolvemos

- Captar pacientes online y generar confianza en un tratamiento a distancia.
- Canalizar toda la comunicación por escrito (WhatsApp y web) sin que Adela atienda llamadas.
- Que Adela prescriba rutinas personalizadas a partir de **su propia biblioteca de vídeos y voces en off**.
- Que Adela tenga **todo el historial de cada paciente en un solo sitio**: cuestionario, consultas, ejercicios, feedback, conversaciones y pagos.
- Cobrar por adelantado y sin gestión manual.

## 3. Objetivos medibles ❓

Pendiente de preguntar a Adela (captación mensual, conversión, adherencia…).

## 4. Servicios y tarifas

### 4.1 Oferta (se mantienen los de la demo)

| Producto | Precio | Duración / contenido | Pago |
|---|---|---|---|
| **Primera consulta** (obligatoria) | ~~45 €~~ **22,50 €** (−50 %) | **25 min** por videollamada | Bizum o tarjeta |
| Sesión suelta | 45 € | 45 min por videollamada, test biomecánico, pautas | Bizum o tarjeta |
| Plan mensual de rutinas | 59 € / mes | Rutinas en vídeo, mini cuestionario, ajuste semanal, consultas por escrito | **Suscripción con tarjeta** |
| Plan premium híbrido | 89 € / mes | Plan de rutinas + 2 videollamadas al mes (45 min) + reevaluación | **Suscripción con tarjeta** |

- Pasarela: **Stripe** (Bizum solo para pagos únicos; suscripciones solo con tarjeta).
- **Facturas:** las emite Adela y se envían a su gestoría. IVA ❓: confirmarlo con la gestoría, porque la asistencia sanitaria de profesionales colegiados puede estar exenta (art. 20.Uno.3º LIVA). Si el CRM llega a emitir facturas, tendría que cumplir la normativa de facturación verificable (VeriFactu).

### 4.2 Servicios destacados en la web

Suelo pélvico · Linfedema · Prevención del envejecimiento (atrofia) · Lesiones deportivas · Lesiones múltiples.
Los textos los redactamos nosotros y Adela los revisa.

## 5. Recorrido del paciente

```
Web ─► Cuestionario clínico ─► Registro ─► Paga 1ª consulta (22,50 €) ─► Reserva hora
   ─► 1ª consulta (25 min) ─► Elige plan (en la web o por enlace de Adela) ─► Paga
   ─► Reserva (si el plan incluye videollamadas) ─► Rutinas en el portal ─► Mini cuestionario diario
   ─► Adela revisa y ajusta ─► … ─► Alta
```

1. **Web:** el visitante conoce el servicio, a Adela ("Quiénes somos") y los servicios destacados.
2. **Cuestionario clínico:**
   - Consentimiento RGPD explícito antes de pedir datos de salud.
   - Paso nuevo **"tipo de problema"** (dolor localizado, suelo pélvico, linfedema, envejecimiento, lesión deportiva, lesiones múltiples). Si es dolor localizado, se elige la zona en la silueta.
   - Campo libre de **comentarios adicionales**.
   - **Adjuntar informes médicos y pruebas** (resonancias, informes…): datos ultrasensibles (ver §8).
3. **Registro:** se crea la cuenta del paciente con los datos personales.
4. **Pago de la primera consulta** con el descuento visible (45 € tachado → 22,50 €). La primera consulta es **obligatoria** para todo paciente nuevo.
5. **Reserva de hora**, solo después de pagar (ver §6).
6. **Primera consulta (25 min):** el paciente cuenta su problema; Adela ya ha revisado el cuestionario, los comentarios y los adjuntos.
7. **Elección del plan**, de dos maneras: el paciente lo elige en la web, o Adela le envía un **enlace de pago** desde el CRM. Siempre se **paga primero y se reserva después**.
8. **Tratamiento:** Adela prescribe la rutina desde su biblioteca (ver §7). El paciente la hace, pulsa **"Ejercicio finalizado"** y rellena el **mini cuestionario de la sesión** (ver §7.3).
9. **Seguimiento:** todo queda en el **historial del paciente** (ver §7.4). Adela responde y ajusta la rutina.

## 6. Agenda y videoconsultas

- **Disponibilidad inicial:** martes y jueves de 16:00 a 20:00 ❓ (por fijar). Debe poder cambiarla Adela.
- **Duraciones:** primera consulta 25 min; sesión normal 45 min. **15 min de descanso** después de cada cita, para que Adela registre lo comentado y se lo envíe al paciente.
- **Pago previo obligatorio** para reservar.
- **No presentado sin justificar:** no se devuelve el importe. Adela puede **reagendar sin coste** si considera justificado el motivo, aunque el paciente no haya avisado.
- **Herramienta de videollamada:** ❓ depende de la cuenta de Google de Adela (pendiente). Se decide en el stack.

## 7. Funcionalidades clave

### 7.1 Biblioteca de vídeos y voces (Adela)
- Adela graba **vídeos estándar** por tipo de dolencia y **audios de voz en off por separado**.
- Los sube **desde su ordenador a través del panel** y los va ampliando con el tiempo.
- Cada vídeo o audio se clasifica (dolencia, zona, nivel…) para encontrarlo rápido.
- La voz en off **se reproduce sobre el vídeo** (con el sonido original silenciado), de modo que un mismo vídeo sirve con distintas voces. Así Adela puede **personalizar el énfasis para un paciente** concreto.
- **Almacenamiento** (propuesta, D-012):
  - **Vídeos y voces genéricos** en **Cloudflare R2**: gratis hasta 10 GB y sin coste por reproducciones; acceso privado con enlaces firmados.
  - **Audios personalizados de un paciente y adjuntos médicos** en el **almacenamiento privado de Supabase**, en el VPS de Francia, porque son datos de salud.

### 7.2 Prescripción de rutinas
Al revisar el caso, Adela monta la rutina eligiendo ejercicios de su biblioteca. Por cada ejercicio indica, con desplegables al estilo de las apps de gimnasio:
- vídeo y voz en off (genérica o grabada para ese paciente);
- **series, repeticiones, frecuencia y duración**;
- **nota para el paciente**.

### 7.3 Mini cuestionario de la sesión (paciente)
Se rellena **una vez por sesión completa** (no por ejercicio), tras pulsar "Ejercicio finalizado":

| Campo | Valores |
|---|---|
| Rigidez | Elevada · Moderada · Ligera · Ninguna |
| Dolor (EVA) | 0 a 10 |
| Estabilidad | Alta · Media · Baja |
| Comentario libre | Texto para Adela |

Todo va al **historial del paciente** y Adela lo ve en su ficha.

### 7.4 Historial del paciente (CRM). **Vital**
Línea temporal por paciente, ordenada por fecha, con:
- **cuestionario inicial**, comentarios y **adjuntos médicos**;
- **consultas**: notas de cada sesión, separadas en **notas privadas** (solo Adela) y **resumen para el paciente** **[supuesto]**;
- **rutinas** prescritas y sus cambios;
- **sesiones realizadas** con su mini cuestionario y comentarios;
- **respuestas de Adela**;
- **conversaciones de WhatsApp** (vía Zernio) y mensajes del portal;
- **pagos** realizados (y facturas, si se integran).

Con gráficas de evolución de dolor, rigidez y estabilidad **[supuesto, deseable]**.

### 7.5 Web pública
- Landing actual con la nueva marca.
- **Quiénes somos:** formación, nº de colegiada y foto real de Adela ❓.
- **Servicios destacados** (§4.2) y tarifas con la oferta de la primera consulta.
- Cuestionario clínico (§5.2) y textos legales ❓.

## 8. Privacidad y seguridad (datos de salud)

Los cuestionarios, notas, adjuntos médicos y feedback son **categoría especial (RGPD art. 9)**. Garantías previstas:
- **Servidor en la UE** (VPS en Francia) con disco cifrado; TLS en todo; copias de seguridad cifradas y fuera del servidor, también en la UE.
- **RLS** en todas las tablas y **almacenamiento privado** para adjuntos y audios personalizados: acceso solo mediante enlaces firmados de corta duración. Nada público.
- **2FA** obligatorio para la cuenta de Adela; registro de accesos a los datos clínicos.
- **Consentimientos** explícitos y versionados: tratamiento de datos de salud, subida de documentos y comunicaciones por WhatsApp.
- **Contratos de encargado del tratamiento** con cada proveedor: VPS, Stripe, Zernio, email…
- Documentación RGPD: **registro de actividades de tratamiento** y valoración de una **evaluación de impacto (EIPD)**. Recomendable que la revise un consultor RGPD ❓.
- Conservación mínima de la historia clínica: 5 años (Ley 41/2002).

## 9. Fuera de alcance (por ahora)

- Atención presencial.
- Instagram y LinkedIn.
- Recepcionista o contestador de voz con IA (D-006).
- App nativa: el portal es web adaptada a móvil.
- Contabilidad. Las facturas las gestiona la gestoría ❓ (ver §4.1).

## 10. Restricciones y pendientes

- **Legales:** RGPD art. 9, LOPDGDD, Ley 41/2002, LSSI, normativa de facturación.
- **Plazos y financiación ❓:** la presentación al Bono Crecimiento Pyme de la JCCM requiere que José Miguel constituya su SL para firmar como partner tecnológico. Mientras tanto se avanza en el proyecto, pero no se puede presentar.
- **Pendiente de Adela:** cuenta de Google, alta de la línea móvil y de WhatsApp Business, email profesional, dominio, datos para "Quiénes somos", vídeos y audios, horario definitivo, objetivos.
