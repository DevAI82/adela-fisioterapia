# AGENTS.md — Guía para agentes de IA y colaboradores

> Proyecto: **Fisioterapia Online con Adela** (Adela Alventosa, fisioterapeuta colegiada).
> Desarrollado por **Altera Soluciones Tecnológicas**.
> Metodología: **SDD — Spec Driven Development**. Ningún código sin spec aprobada.

Este fichero lo lee cualquier agente (Claude Code, Cursor, Codex, Copilot…) antes de tocar el proyecto.
El estado vivo y las decisiones están en [`MEMORY.md`](MEMORY.md). Las especificaciones, en [`specs/`](specs/).

---

## 1. Orden de lectura obligatorio al empezar una sesión

1. `AGENTS.md` (este fichero): reglas.
2. `MEMORY.md`: estado actual, decisiones tomadas y pendientes.
3. `specs/00-brief.md`, `specs/01-stack.md` y `specs/02-plan.md`: qué construimos, con qué y en qué orden.
4. La spec de la funcionalidad en curso (`specs/features/NNN-*.md`).

## 2. Flujo SDD

```
Brief ─► Spec ─► Plan ─► Tareas ─► Implementación ─► Verificación ─► Memoria
```

| Fase | Entregable | Quién aprueba |
|---|---|---|
| **Spec** | `specs/features/NNN-nombre.md` desde `specs/_plantilla-spec.md`: qué y por qué, criterios de aceptación | José Miguel (y Adela si afecta al paciente o a la clínica) |
| **Plan** | Sección *Plan técnico* de la spec: cómo, ficheros, datos, riesgos | José Miguel |
| **Tareas** | Checklist en la spec, cada tarea pequeña y verificable | — |
| **Implementación** | Código en una rama `feat/NNN-nombre`, commits pequeños | — |
| **Verificación** | Cada criterio de aceptación comprobado (test o prueba manual descrita) | José Miguel |
| **Memoria** | Entrada en `MEMORY.md` (decisiones, cambios de estado) | — |

Reglas:
- **Sin spec aprobada no se escribe código de producción.** Prototipos y spikes sí, marcados como tales.
- Si durante la implementación la spec resulta incorrecta, **se para y se actualiza la spec**; no se improvisa en el código.
- Las decisiones de arquitectura se registran en `MEMORY.md › Decisiones` con fecha y motivo.
- Estados de una spec: `borrador` → `aprobada` → `en curso` → `hecha` (o `descartada`).

## 3. Estructura del repositorio

```
/                       Sitio publicado en GitHub Pages (prototipo interactivo actual)
├── index.html          Prototipo: web pública, CRM, portal paciente y flujo de teléfono
├── mockup_interactivo.html  Copia de index.html (se mantiene sincronizada)
├── presentacion.html / VER PRESENTACION.html   Dossier de la propuesta inicial
├── logo-*.png, favicon.png, apple-touch-icon.png, og-adela-fisio.jpg   Marca
├── AGENTS.md           Este fichero
├── CLAUDE.md           Puntero a AGENTS.md para Claude Code
├── MEMORY.md           Memoria del proyecto: estado, decisiones y pendientes
├── .env.example        Plantilla de variables (el .env real nunca se sube)
└── specs/
    ├── 00-brief.md     Brief del cliente
    ├── 01-stack.md     Stack tecnológico y arquitectura
    ├── 02-plan.md      Fases y orden de las specs
    ├── _plantilla-spec.md
    └── features/       Una spec por funcionalidad (NNN-nombre.md)
```

La estructura de la aplicación de producción se define en `specs/01-stack.md` y se añadirá aquí cuando esté aprobada.

## 4. Identidad de marca (fuente: logo oficial del cliente)

| Token | Hex | Uso |
|---|---|---|
| `brand-500` | `#3C923A` | Verde del logo. Color principal, botones (`brand-600/700` para texto blanco AA) |
| `ocean-600` | `#077AB9` | Azul "Online". Acentos, enlaces, titulares destacados |
| `ocean-700` | `#056F9C` | Azul "Adela". Texto azul sobre blanco |
| `ocean-500` | `#139CD8` | Celeste de las olas. Decorativo, no para texto sobre blanco |
| `sun-400` | `#FDCC1C` | Amarillo del sol. Solo detalles; nunca texto sobre blanco |
| `sand-50` | `#FBFAF8` | Fondo general |

- Nombre comercial: **"Fisioterapia Online con Adela"**. En espacios pequeños: isotipo (`logo-isotipo.png`) + logotipo en HTML.
- Contraste mínimo **WCAG AA** (4,5:1 en texto normal). Blanco solo sobre `brand-600` o más oscuro, u `ocean-600` o más oscuro.
- Tipografías: Plus Jakarta Sans (texto), Playfair Display (titulares), Caveat (firma "Adela").
- No inventar colores nuevos: si hace falta uno, se añade a la paleta y se documenta aquí.

## 5. Reglas no negociables

### Datos de salud (RGPD art. 9 y Ley 41/2002)
- Los datos clínicos son **categoría especial**. Consentimiento explícito **antes** de recoger síntomas.
- Las notas clínicas privadas de Adela no las ve nunca el paciente: protección por **RLS** en base de datos, no solo en la interfaz.
- **Nunca** usar datos reales de pacientes en desarrollo, pruebas, capturas, prompts de IA ni logs. Solo datos ficticios.
- Servidores y proveedores con datos de pacientes **en la UE**. Cualquier proveedor nuevo se valida antes (contrato de encargado del tratamiento).
- La historia clínica se conserva un mínimo de 5 años. No implementar borrados en cascada sobre historia clínica sin spec.

### Secretos
- Las claves solo van en `.env` (local) o en el gestor de secretos del proveedor. **Nunca** en el código, en commits, en issues ni en el chat.
- Lo que lleve prefijo `PUBLIC_` acaba en el navegador: jamás una clave secreta con ese prefijo.
- `SUPABASE_SERVICE_ROLE_KEY` solo en servidor o Edge Functions.
- Si se filtra una clave: rotarla primero y documentarlo en `MEMORY.md` después.

### Calidad
- Idioma: interfaz, specs, commits y comentarios **en español**. Identificadores de código en inglés.
- Commits: [Conventional Commits](https://www.conventionalcommits.org/es/) (`feat:`, `fix:`, `docs:`, `chore:`…), con el ámbito cuando aporte (`feat(crm): …`).
- Diseño responsive desde 360 px, accesible por teclado, con `alt` en imágenes.
- No añadir dependencias sin justificarlas en la spec.
- `index.html` y `mockup_interactivo.html` deben ser idénticos mientras convivan.

## 6. Definición de "hecho"

- [ ] Todos los criterios de aceptación de la spec verificados.
- [ ] Sin secretos ni datos reales en el diff.
- [ ] Revisado en móvil (390 px) y escritorio (1280 px).
- [ ] Sin errores en la consola del navegador.
- [ ] Spec en estado `hecha` y `MEMORY.md` actualizado.

## 7. Cómo trabajar con el agente

- Antes de un cambio grande, el agente propone el plan y espera el visto bueno.
- Si falta información del cliente, se pregunta; no se inventa (precios, horarios, nº de colegiada, textos legales…).
- Al cerrar una sesión, el agente actualiza `MEMORY.md › Registro de sesiones` con lo hecho y lo pendiente.
