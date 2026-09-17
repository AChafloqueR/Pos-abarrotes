# Roadmap después del mes 1

Lo que este proyecto YA incluye (MVP): login con roles, catálogo, venta con carrito, impresión de ticket, apertura/cierre de caja, alertas de stock bajo, historial de ventas, panel admin y RLS completo.

Ideas para seguir sumando valor al portafolio una vez desplegado:

1. **Reportes con gráficos** en el panel (ventas por día/semana, productos más vendidos) — usando `recharts`, ya instalado.
2. **Boleta/factura electrónica SUNAT** vía un PSE (ej. Nubefact, Facturador SUNAT) — buen tema para mostrar integración con APIs externas.
3. **Modo offline** en la app (guardar ventas en SQLite local y sincronizar cuando vuelva la señal) — muy valorado en un negocio real de barrio.
4. **Notificaciones** de stock bajo por WhatsApp/correo (Supabase Edge Function + cron).
5. **Multi-sucursal** real si algún día abres una segunda tienda — el esquema de base de datos ya está listo (`tienda_id` en todo).
6. **Tests automatizados** (Flutter widget tests, Playwright para el panel) — súmalo como sección de "calidad" en tu CV.
7. **Publicar el APK firmado** en Google Play (cuenta de desarrollador, ficha de la app) si quieres distribuirlo más allá de tu propio celular.

Para tu portafolio/CV: este proyecto demuestra base de datos relacional con seguridad a nivel de fila, autenticación con roles, apps multiplataforma (web + móvil), integración con hardware (impresora térmica) y CI/CD — cúbrelo en tu CV como "Sistema POS full-stack con Next.js, Flutter y Supabase (PostgreSQL, RLS, Auth)".
