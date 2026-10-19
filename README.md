# 💰 Loan Collector App

App de cobro de préstamos con interés — Flutter + PWA con UI ultra moderna.

## 🚀 Inicio rápido

```bash
flutter pub get
flutter run
```

## 📦 Build para Web (PWA)

```bash
flutter build web --release
```

## ✨ Características

- 🎨 UI ultra moderna con gradientes y glassmorphism
- 🔊 Sonidos y emoticones en cada interacción
- 🚨 Alarmas de mora con severidad por colores (🟡🟠🔴)
- 👥 Ficha completa del cliente con dirección, teléfonos y apoderado
- 💾 Persistencia total + modo offline con sincronización
- 🔔 Notificaciones push al propietario en tiempo real
- 💵 Registro de pagos con fecha, hora, monto, cuotas y saldo

## 🗂️ Estructura

```
lib/
├── core/
│   ├── theme/       # Colores, gradientes, tipografía
│   └── design/      # Emojis y sonidos
├── models/          # Modelos de datos
├── services/        # Cálculo de interés, notificaciones, sync
├── providers/       # Estado con Riverpod
├── repositories/    # Acceso a datos
├── widgets/         # Componentes reutilizables
└── screens/         # Pantallas
```

## 📄 Licencia

MIT
