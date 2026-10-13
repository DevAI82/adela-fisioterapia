# 001 · Atención telefónica: mensaje fijo y derivación a WhatsApp, email o web

| Campo | Valor |
|---|---|
| Estado | `aprobada` (funcionalidad). Implementación **bloqueada** hasta dar de alta la línea |
| Módulo | M7 · Atención telefónica (ver `00-brief.md §4`) |
| Prioridad | Alta (sin ella las llamadas se pierden) |
| Aprobada por | José Miguel, tras hablarlo con Adela (2026-10-13) |
| Fecha | 2026-10-13 |

## 1. Contexto y objetivo
Adela no va a atender el teléfono ni quiere, por ahora, una recepcionista con IA (ElevenLabs queda fuera: D-006).
Quiere que **toda la comunicación sea por escrito** (WhatsApp, email o web) para gestionarla a su ritmo.
El objetivo es que ninguna llamada se pierda sin que el paciente sepa cómo contactar.

## 2. Historias de usuario
- Como **paciente que llama**, quiero saber enseguida cómo contactar para no quedarme sin respuesta.
- Como **Adela**, quiero no recibir llamadas ni tener que escuchar mensajes de voz, y recibir todas las consultas por escrito.

## 3. Criterios de aceptación
- [ ] **CA-1:** Dado cualquier día y hora, cuando alguien llama al móvil de la clínica, entonces escucha **siempre** el mensaje grabado. El teléfono no suena para Adela.
- [ ] **CA-2:** El mensaje dura 25 segundos como máximo y menciona, en este orden: WhatsApp al mismo número, email y web.
- [ ] **CA-3:** Tras el mensaje, la llamada termina **sin buzón de voz**. Si el operador no permite desactivarlo, el mensaje lo dice expresamente ("no escuchamos mensajes de voz") y se registra como desviación en §10.
- [ ] **CA-4:** El número del teléfono y el de WhatsApp Business son el mismo.
- [ ] **CA-5:** El email y la web que se citan en el mensaje existen y funcionan antes de activar el mensaje.
- [ ] **CA-6:** Las consultas que llegan por WhatsApp, email y web acaban en la bandeja de conversaciones del panel. Esta parte depende de la spec de la bandeja omnicanal (pendiente).
- [ ] **CA-7:** El prototipo muestra este flujo en la pestaña "Teléfono → WhatsApp". ✅ Hecho el 13/10/2026.

## 4. Fuera de alcance
- Recepcionista o contestador con IA (ElevenLabs u otro). Se podrá retomar en una fase futura.
- Mensaje automático de WhatsApp o SMS tras una llamada perdida (posible mejora futura; exige plantilla aprobada por Meta y revisión de RGPD).
- Centralita con horarios u opciones de menú.

## 5. Datos y privacidad
- No se graban llamadas ni se guardan datos del llamante. Sin datos de salud en este canal.
- Si en el futuro se registran las llamadas perdidas (número y hora), habrá que actualizar esta spec y el registro de tratamientos.

## 6. Diseño / UX
Texto del mensaje (borrador; Adela lo puede grabar con su voz o generarse una sola vez):

> «Hola, has llamado a Fisioterapia Online con Adela. En este momento no podemos atenderte por teléfono.
> Escríbenos por WhatsApp a este mismo número, envíanos un email a **[email pendiente]** o entra en **[web pendiente]**
> y rellena el cuestionario de valoración. Te responderemos lo antes posible. ¡Gracias!»

En el prototipo se omiten el email y la dirección web hasta tenerlos.

## 7. Plan técnico
Depende del operador, que aún no está elegido. Opciones, por orden de preferencia:

| Opción | Cómo | Cumple CA-3 (sin buzón) |
|---|---|---|
| A. Función del operador | Desvío **incondicional** de todas las llamadas al buzón con un mensaje personalizado y la grabación de mensajes desactivada (si lo permite) | Depende del operador |
| B. Centralita virtual | Desvío incondicional del móvil a un número virtual configurado con "reproducir mensaje y colgar" | Sí |

Puntos a comprobar al elegir el operador:
- Que permita el desvío incondicional y el mensaje personalizado, y si deja desactivar la grabación de mensajes.
- Coste de los desvíos (a un número virtual pueden facturarse).
- **WhatsApp Business en el mismo número:** la línea debe poder recibir el SMS o la llamada de verificación de Meta. Ojo: con el desvío incondicional activo, la verificación por llamada no llegaría. Hay que verificar WhatsApp **antes** de activar el desvío, o hacerlo por SMS.
- Si se conecta WhatsApp a Zernio o a la API oficial, comprobar que se puede seguir usando la app de WhatsApp Business en el móvil con ese número (modo coexistencia), o elegir uno de los dos.

## 8. Tareas
- [x] T1 Prototipo: sustituir la pestaña de voz IA por el flujo llamada → mensaje → canales.
- [ ] T2 Adela da de alta la línea móvil (operador pendiente).
- [ ] T3 Adela contrata o activa WhatsApp Business en ese número.
- [ ] T4 Definir el email profesional y el dominio de la web.
- [ ] T5 Cerrar el texto del mensaje con el email y la web reales; grabarlo.
- [ ] T6 Configurar la opción A o B según el operador.
- [ ] T7 Verificar CA-1 a CA-5 con llamadas de prueba (desde otro móvil y desde un fijo, a varias horas).

## 9. Verificación
- T1 verificado con Playwright en escritorio (1280 px) y móvil (390 px): la simulación reproduce el mensaje, termina y resalta los canales; sin errores de JavaScript.

## 10. Notas y decisiones
- 2026-10-13: Adela confirma que el mensaje salta **siempre** (nunca coge el teléfono) y que el WhatsApp será el mismo número.
