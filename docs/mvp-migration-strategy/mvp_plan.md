# Plan MVP Simplificado - Enatega
**Enfoque: Admin + Customer App (Sin App Repartidor Inicial)**

---

## 🎯 Estrategia del MVP

### Flujo Operativo
```
Cliente (App) → Hace Pedido 
    ↓
Backend (Hasura/PostgreSQL) → Guarda Orden
    ↓
Admin (Dashboard) → Ve orden nueva
    ↓
Admin → Notifica repartidor por WhatsApp (MANUAL)
    ↓
Repartidor → Recoge y entrega
    ↓
Admin → Marca orden como entregada en dashboard
```

### Por Qué Este Enfoque
✅ Más rápido de implementar
✅ Menos código que mantener
✅ Permite validar el negocio primero
✅ WhatsApp es familiar para todos
✅ Se puede agregar app de repartidor después

---

## 📱 Alcance del MVP

### ✅ **Incluido**
1. **Dashboard de Admin** (80% completo)
   - Login de admin ✅
   - Ver órdenes en tiempo real
   - Ver detalles de cada orden
   - Cambiar estado de orden manualmente
   - Gestionar restaurantes ✅
   - Gestionar repartidores (solo datos básicos) ✅
   
2. **App de Cliente** (Por hacer)
   - Registro y login de cliente
   - Ver restaurantes disponibles
   - Ver menú del restaurante
   - Agregar items al carrito
   - Hacer checkout y pagar (mock)
   - Ver estado de orden
   - Ver historial de órdenes

### ❌ **NO Incluido en MVP Inicial**
- App de Repartidor (notificación manual por WhatsApp)
- App de Vendor (admin gestiona por ellos)
- Notificaciones push automatizadas
- Integración de pagos real
- Seguimiento GPS en tiempo real
- Asignación automática de repartidores

---

## 🚀 Plan de Implementación

### **Fase 1: Admin Dashboard - Gestión de Órdenes** ✅ Casi Completo

#### Páginas Faltantes
- [ ] **Página de Órdenes**
  - Lista de todas las órdenes (más recientes primero)
  - Filtros: Por estado, por fecha, por restaurante
  - Vista de tarjetas con: #orden, cliente, restaurante, total, estado
  - Click para ver detalles completos
  
- [ ] **Detalles de Orden (Modal/Página)**
  - Información del cliente (nombre, teléfono, dirección)
  - Información del restaurante
  - Items ordenados (con cantidades y precios)
  - Subtotal, impuestos, delivery, total
  - **Botón: "Notificar Repartidor"** (copia número de WhatsApp)
  - **Selector de estado**: Pendiente → En Preparación → Lista → En Camino → Entregada
  - Timestamp de cada cambio de estado

#### GraphQL Necesario
- [ ] Query `orders` (paginada, con filtros)
- [ ] Query `order` (detalle individual)
- [ ] Mutation `updateOrderStatus`

---

### **Fase 2: Customer App - Flujo Completo de Pedido** 🔄 Siguiente

#### 2.1 Configuración Inicial
- [ ] Actualizar `environment.js`:
  ```javascript
  GRAPHQL_URL: 'http://TU_IP:8080/v1/graphql'
  WS_GRAPHQL_URL: 'ws://TU_IP:8080/v1/graphql'
  ```
- [ ] Probar conexión con backend

#### 2.2 Autenticación
- [ ] **Registro de Cliente**
  - Formulario: nombre, email, teléfono, contraseña
  - Mutación `createAccount`
  - Login automático después de registro
  
- [ ] **Login de Cliente**
  - Email + contraseña
  - Guardar token en AsyncStorage
  - Redirigir a home

- [ ] **Perfil**
  - Ver datos del usuario
  - Editar nombre, teléfono
  - Cambiar contraseña
  - Cerrar sesión

#### 2.3 Navegación de Restaurantes
- [ ] **Pantalla Principal**
  - Query `restaurants` (filtrados por zona del usuario)
  - Tarjetas con: nombre, imagen, categoría, rating
  - Click para ver menú
  
- [ ] **Búsqueda y Filtros** (Opcional para MVP)
  - Buscar por nombre
  - Filtrar por categoría/cocina

#### 2.4 Menú y Carrito
- [ ] **Pantalla de Menú**
  - Query `restaurant` con sus `foodItems`
  - Lista de categorías
  - Lista de items con imagen, nombre, descripción, precio
  - Botón "Agregar al carrito"
  
- [ ] **Carrito**
  - Ver items agregados
  - Cambiar cantidad (+/-)
  - Eliminar item
  - Ver subtotal
  - Botón "Proceder al checkout"

#### 2.5 Checkout y Pago
- [ ] **Pantalla de Checkout**
  - Dirección de entrega (input manual para MVP)
  - Método de pago: "Efectivo" o "Tarjeta" (ambos mock)
  - Resumen del pedido
  - Total final (subtotal + delivery + impuestos)
  - Botón "Confirmar Pedido"
  
- [ ] **Confirmación**
  - Mutación `createOrder`
  - Mostrar mensaje de éxito
  - Número de orden generado
  - Redirigir a "Mis Órdenes"

#### 2.6 Seguimiento de Órdenes
- [ ] **Mis Órdenes**
  - Query `orders` del usuario
  - Tabs: Activas / Historial
  - Tarjetas con: número, restaurante, estado, total
  
- [ ] **Detalle de Orden**
  - Ver items ordenados
  - Ver estado actual
  - Timeline de estados (opcional)
  - Botón "Llamar al restaurante"
  - Botón "Ayuda/Soporte" (WhatsApp al admin)

---

## 🗄️ Base de Datos - Cambios Necesarios

### Tablas Existentes (Usar)
- ✅ `users` (clientes y admins)
- ✅ `restaurants`
- ✅ `food_items`
- ✅ `categories`
- ✅ `zones`
- ✅ `riders_data` (solo para info, no app)
- ✅ `orders`
- ✅ `order_items`
- ✅ `addresses`

### Queries/Mutations a Crear

#### Para Customer App
```graphql
# Autenticación
mutation createAccount($name: String!, $email: String!, $phone: String!, $password: String!)
mutation login($email: String!, $password: String!)

# Restaurantes
query restaurants($zoneId: uuid)
query restaurant($id: uuid!)

# Órdenes
mutation createOrder($restaurantId: uuid!, $items: [OrderItemInput!]!, $address: String!, $paymentMethod: String!)
query myOrders($userId: String!)
query order($id: uuid!)
```

#### Para Admin Dashboard
```graphql
query orders($limit: Int, $offset: Int, $status: String, $date: date)
query order($id: uuid!)
mutation updateOrderStatus($id: uuid!, $status: String!)
```

---

## 🧪 Testing del MVP

### Test Manual - Flujo Completo
1. **Como Cliente:**
   - ✅ Registrarse en la app
   - ✅ Ver restaurantes disponibles
   - ✅ Agregar items al carrito
   - ✅ Hacer checkout (mock pago)
   - ✅ Confirmar que orden se crea
   - ✅ Ver orden en "Mis Órdenes"

2. **Como Admin:**
   - ✅ Ver la orden nueva en dashboard
   - ✅ Ver detalles completos
   - ✅ Copiar datos del cliente
   - ✅ Notificar repartidor por WhatsApp
   - ✅ Cambiar estado a "En Preparación"
   - ✅ Cambiar estado a "En Camino"
   - ✅ Marcar como "Entregada"

3. **Verificar:**
   - ✅ Cliente ve cambios de estado en tiempo real (o al refrescar)
   - ✅ Orden aparece en historial después de entregada

---

## 📋 Checklist de Implementación

### Esta Semana - Admin Dashboard
- [ ] Crear página de órdenes
- [ ] Crear vista de detalle de orden
- [ ] Implementar query `orders`
- [ ] Implementar mutation `updateOrderStatus`
- [ ] Agregar botón "Copiar WhatsApp" para notificar repartidor
- [ ] Probar flujo completo desde orden mock

### Próxima Semana - Customer App
- [ ] Configurar `environment.js`
- [ ] Implementar registro/login
- [ ] Implementar vista de restaurantes
- [ ] Implementar vista de menú
- [ ] Implementar carrito
- [ ] Implementar checkout
- [ ] Implementar "Mis Órdenes"
- [ ] Testing end-to-end

### Opcional - Mejoras Futuras
- [ ] Notificaciones push cuando cambia estado
- [ ] App de repartidor (reemplaza WhatsApp)
- [ ] Integración de pagos real (Stripe/PayPal)
- [ ] Seguimiento GPS
- [ ] Ratings y reseñas
- [ ] Sistema de cupones

---

## 🎯 Criterio de Éxito del MVP

### ✅ MVP Exitoso Si:
1. Cliente puede registrarse y hacer login
2. Cliente puede ver restaurantes y menú
3. Cliente puede hacer un pedido completo
4. Admin ve la orden en dashboard
5. Admin puede cambiar el estado de la orden
6. Cliente ve el estado actualizado

### 🚀 Listo para Lanzar Si:
- Funciona el flujo completo 5 veces seguidas sin errores
- Tienes al menos 3 restaurantes con menús completos
- Tutorial/video de cómo usar el sistema (para admin y clientes)

---

## 📞 Flujo WhatsApp Sugerido

Cuando admin ve orden nueva, copia este mensaje:

```
🍔 NUEVO PEDIDO #[NUMERO_ORDEN]

📍 Recoger en: [RESTAURANTE]
[DIRECCIÓN_RESTAURANTE]

📦 Entregar a: [NOMBRE_CLIENTE]
📱 Tel: [TELEFONO_CLIENTE]
📍 [DIRECCIÓN_CLIENTE]

💰 Total a cobrar: $[TOTAL]
💳 Pago: [EFECTIVO/TARJETA]

Items:
[LISTA_DE_ITEMS]

¿Puedes tomar este pedido? Responde SÍ para confirmar.
```

---

## ⏱️ Timeline Estimado

| Tarea | Tiempo | Estado |
|-------|--------|--------|
| Admin - Página de órdenes | 4-6 hrs | Pendiente |
| Customer - Setup y auth | 3-4 hrs | Pendiente |
| Customer - Restaurantes y menú | 4-6 hrs | Pendiente |
| Customer - Carrito y checkout | 6-8 hrs | Pendiente |
| Customer - Tracking de órdenes | 3-4 hrs | Pendiente |
| Testing integración | 4-6 hrs | Pendiente |
| **TOTAL** | **24-34 hrs** | - |

---

## 🔐 Seguridad Mínima para MVP

- [ ] Contraseñas hasheadas (bcrypt)
- [ ] JWT tokens con expiración
- [ ] Validación de inputs (evitar SQL injection)
- [ ] CORS configurado correctamente
- [ ] HTTPS en producción (cuando despliegues)

**Para desarrollo local está OK con mock/básico**
