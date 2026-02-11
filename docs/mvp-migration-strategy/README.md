# Documentación de Migración MVP - Enatega

Esta carpeta contiene toda la documentación relacionada con la migración y estrategia del MVP de Enatega.

## 📁 Archivos

### [`mvp_plan.md`](./mvp_plan.md)
Plan completo de implementación del MVP simplificado:
- Estrategia operativa (Admin + Customer App, sin Rider App inicial)
- Flujo de trabajo con WhatsApp para notificación de repartidores
- Checklist detallado de features
- Timeline estimado
- Criterios de éxito

### [`task.md`](./task.md)
Checklist de tareas organizadas por fases:
- Fase 1: Admin Dashboard - Gestión de Órdenes
- Fase 2: Customer App - Flujo Completo
- Fase 3: Testing End-to-End
- Mejoras Futuras
- Deuda Técnica

## 🎯 Estrategia MVP

**Flujo Simplificado:**
```
Cliente (App) → Hace Pedido 
    ↓
Backend (Hasura) → Guarda Orden
    ↓
Admin (Dashboard) → Ve orden nueva
    ↓
Admin → Notifica repartidor por WhatsApp (MANUAL)
    ↓
Repartidor → Recoge y entrega
    ↓
Admin → Marca orden como entregada
```

## ✅ Estado Actual

- **Backend**: PostgreSQL + Hasura ✅
- **Admin Dashboard**: 80% completo ✅
  - Login funcionando
  - Dashboard con estadísticas
  - Gestión de restaurantes, repartidores, zonas
  - **Falta**: Página de órdenes
- **Customer App**: Por iniciar 🔄
- **Rider App**: No incluido en MVP (WhatsApp manual)

## 📞 Contacto

Para preguntas sobre la migración, contactar al equipo de desarrollo.

---

**Última actualización**: 2026-02-10
