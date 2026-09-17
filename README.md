# POS Abarrotes 🛒

Sistema de punto de venta (POS) para tienda de abarrotes: app móvil para el cajero, panel web de administración y base de datos en la nube.

## Estructura del monorepo

```
pos-abarrotes/
├── mobile/          # App Flutter (Android/iOS) — venta en mostrador + ticketera Bluetooth
├── web/             # Panel admin Next.js — inventario, productos, reportes, usuarios
├── supabase/        # Esquema SQL, políticas de seguridad (RLS), funciones
├── docs/            # Arquitectura, guía de despliegue, seguridad
└── .github/workflows/  # CI (lint/test automático en cada push)
```

## Stack tecnológico

| Capa | Tecnología | Por qué |
|---|---|---|
| Base de datos + Auth + Storage | **Supabase** (Postgres) | Backend gestionado, seguridad a nivel de fila (RLS), gratis para empezar |
| Panel administrativo | **Next.js 14 + TypeScript + Tailwind** | Se despliega gratis en **Vercel**, ideal para inventario/reportes desde una PC |
| App de venta (mostrador) | **Flutter** | Un solo código para Android/iOS, funciona bien con impresoras térmicas Bluetooth |
| Impresión de tickets | ESC/POS sobre Bluetooth | Compatible con la mayoría de ticketeras térmicas 58mm/80mm que se venden en Perú |

## Primeros pasos

1. Lee `docs/ARQUITECTURA.md` para entender el modelo de datos y el flujo de venta.
2. Sigue `docs/DESPLIEGUE.md` paso a paso para crear tus cuentas y desplegar (GitHub → Supabase → Vercel → Flutter).
3. Revisa `docs/SEGURIDAD.md` antes de poner el sistema en producción con dinero real.
4. Usa el organizador de tareas (documento aparte) para seguir el plan día a día durante el mes.

## Estado del proyecto

MVP funcional: login con roles, catálogo de productos, venta con carrito, impresión de ticket, cierre de caja, reportes básicos y panel admin. Pensado como base sólida para portafolio — ver `docs/ROADMAP.md` para lo que sigue después del mes 1.
