# Tareas MVP Simplificado
**Admin + Customer App (Sin App Repartidor)**

## Fase 1: Admin Dashboard - Gestión de Órdenes
- [x] Backend y Hasura funcionando
- [x] Login de admin
- [x] Dashboard con estadísticas
- [x] Gestión de restaurantes
- [x] Gestión de repartidores (datos básicos)
- [x] Gestión de zonas
- [ ] **Página de Órdenes**
  - [ ] Lista de órdenes (más recientes primero)
  - [ ] Filtros por estado, fecha, restaurante
  - [ ] Click para ver detalles
- [ ] **Detalle de Orden**
  - [ ] Información completa (cliente, restaurante, items)
  - [ ] Botón "Copiar WhatsApp" (para notificar repartidor)
  - [ ] Selector de estado de orden
  - [ ] Historial de cambios de estado
- [ ] **GraphQL**
  - [ ] Query `orders` (paginada, filtrable)
  - [ ] Query `order` (detalle)
  - [ ] Mutation `updateOrderStatus`

## Fase 2: Customer App - Flujo Completo
- [ ] **Configuración**
  - [ ] Actualizar `environment.js` con IP del backend
  - [ ] Probar conexión GraphQL
- [ ] **Autenticación**
  - [ ] Pantalla de registro
  - [ ] Pantalla de login
  - [ ] Perfil de usuario
  - [ ] Logout
- [ ] **Restaurantes**
  - [ ] Listar restaurantes disponibles
  - [ ] Ver menú del restaurante
  - [ ] Búsqueda (opcional)
- [ ] **Carrito y Checkout**
  - [ ] Agregar items al carrito
  - [ ] Ver carrito (modificar cantidades)
  - [ ] Checkout (dirección + método de pago)
  - [ ] Crear orden (mutation `createOrder`)
  - [ ] Pantalla de confirmación
- [ ] **Mis Órdenes**
  - [ ] Ver órdenes activas
  - [ ] Ver historial de órdenes
  - [ ] Ver detalle de orden
  - [ ] Ver estado en tiempo real
- [ ] **GraphQL**
  - [ ] Mutation `createAccount`
  - [ ] Mutation `login`
  - [ ] Query `restaurants`
  - [ ] Query `restaurant` (con menú)
  - [ ] Mutation `createOrder`
  - [ ] Query `myOrders`

## Fase 3: Testing End-to-End
- [ ] **Flujo Cliente**
  - [ ] Registro → Login → Ver restaurantes → Agregar al carrito → Checkout → Confirmar
- [ ] **Flujo Admin**
  - [ ] Ver orden nueva → Ver detalles → Notificar repartidor (WhatsApp) → Cambiar estados
- [ ] **Verificación**
  - [ ] Cliente ve cambios de estado
  - [ ] Orden completa aparece en historial
- [ ] **Testing con Datos Reales**
  - [ ] Al menos 3 restaurantes con menús
  - [ ] Al menos 5 órdenes de prueba completas

## Mejoras Futuras (Post-MVP)
- [ ] App de Repartidor (reemplaza WhatsApp)
- [ ] Notificaciones push automatizadas
- [ ] Seguimiento GPS en tiempo real
- [ ] Integración de pagos real
- [ ] Sistema de ratings y reseñas
- [ ] App de Vendor

## Deuda Técnica
- [ ] Hashear contraseñas (bcrypt)
- [ ] JWT tokens reales
- [ ] Permisos de Hasura por rol
- [ ] Validación de inputs
- [ ] HTTPS para producción
