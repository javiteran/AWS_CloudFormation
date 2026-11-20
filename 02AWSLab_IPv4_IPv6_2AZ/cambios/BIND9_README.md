# ✅ BIND9 Configuration - Implementación Completada

## 📋 Resumen Ejecutivo

Se ha **configurado BIND9** en la instancia Ubuntu mediante el UserData de CloudFormation. El archivo `/etc/bind/named.conf.options` se **crea y configura automáticamente** cuando se lanza la instancia.

---

## 🔧 Cambios Realizados

### Archivo Modificado
**Path**: `C:\Users\javier.teran\Documents\github\AWS_CloudFormation\02AWSLab_IPv4_IPv6_2AZ\00AWSLab01_IPv4_IPv6_2AZ.yaml`

### Cambio
Se modificó el **UserData** de la instancia `UbuntuInstance` para incluir comandos que crean y configuran `/etc/bind/named.conf.options`

### Ubicación en el YAML
- **Líneas**: 277-305
- **Recurso**: `UbuntuInstance`
- **Sección**: `UserData`
- **Cambio de tipo**: ADICIÓN (no modificación destructiva)

---

## 📊 Configuración BIND9 Generada

### Con parámetros por defecto (NN=01, RedBase=26):

```
┌─────────────────────────────────────────────────────────────┐
│ /etc/bind/named.conf.options                                │
├─────────────────────────────────────────────────────────────┤
│ options {                                                   │
│     directory "/var/cache/bind";                            │
│                                                             │
│     // Habilitar la recursión                              │
│     recursion yes;                                          │
│                                                             │
│     // Permitir la recursión solo a tu red local            │
│     allow-recursion {                                       │
│         localhost;                                          │
│         10.26.101.0/24;  ← Subred Ubuntu                   │
│         10.26.201.0/24;  ← Subred Windows                  │
│     };                                                      │
│                                                             │
│     dnssec-validation auto;                                │
│     listen-on { any; };                                    │
│     listen-on-v6 { any; };                                 │
│ };                                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Detalles de la Configuración

| Opción | Valor | Propósito |
|--------|-------|----------|
| **directory** | `/var/cache/bind` | Ubicación de caché de BIND9 |
| **recursion** | `yes` | Permite resolución recursiva de nombres |
| **allow-recursion** | localhost, 10.26.1NN.0/24, 10.26.2NN.0/24 | Limita quién puede hacer consultas recursivas (seguridad) |
| **dnssec-validation** | `auto` | Valida automáticamente firmas DNSSEC |
| **listen-on** | `any` | Escucha en todas las interfaces IPv4 |
| **listen-on-v6** | `any` | Escucha en todas las interfaces IPv6 |

---

## 🚀 Flujo de Despliegue

```
1. Desplegar CloudFormation
   ↓
2. Lanzar instancia Ubuntu
   ↓
3. Ejecutar UserData
   ├─ apt-get update && upgrade
   ├─ apt-get install bind9  ← BIND9 se instala
   ├─ apt-get install apache2
   ├─ Crear /etc/bind/named.conf.options  ← NUEVO
   ├─ Instalar amazon-ssm-agent
   └─ systemctl restart bind9  ← BIND9 se reinicia con nueva config
   ↓
4. BIND9 está LISTO
   ├─ Escuchando puerto 53/TCP
   ├─ Escuchando puerto 53/UDP
   ├─ Configuración cargada
   └─ Listo para resolver nombres
```

---

## 🔐 Seguridad

### allow-recursion
Restringe las consultas recursivas a:
- **localhost**: La misma instancia
- **10.26.1NN.0/24**: Instancias en Subred Pública 1 (Ubuntu)
- **10.26.2NN.0/24**: Instancias en Subred Pública 2 (Windows)

**Beneficio**: Evita que el servidor DNS sea explotado por recursión desde Internet

---

## ✅ Validación Post-Deployment

### 1. Conectar a Ubuntu
```bash
ssh -i vockey.pem ubuntu@<ELASTIC_IP>
```

### 2. Verificar que el archivo existe
```bash
cat /etc/bind/named.conf.options
# Debe mostrar la configuración completamente
```

### 3. Verificar BIND9 está corriendo
```bash
sudo systemctl status bind9
# Debería mostrar: active (running)
```

### 4. Verificar puerto 53
```bash
sudo netstat -tlnp | grep :53
# Debería mostrar:
# tcp   0  0 0.0.0.0:53   0.0.0.0:*   LISTEN    PID/named
# tcp6  0  0 :::53        :::*        LISTEN    PID/named
```

### 5. Probar resolución DNS (desde otra instancia)
```bash
nslookup google.com 10.26.101.100
dig @10.26.101.100 example.com
# Debería resolver sin errores
```

---

## 💡 Opciones Comentadas

### Forwarders (deshabilitados por defecto)
```bash
//forwarders {
//    8.8.8.8;      ← Google DNS
//    1.1.1.1;      ← Cloudflare DNS
//};
```

**Para habilitar:**
1. SSH a Ubuntu
2. `sudo nano /etc/bind/named.conf.options`
3. Descomenta las líneas (elimina `//`)
4. Guarda (Ctrl+X, Y, Enter)
5. `sudo systemctl restart bind9`

---

## 📋 Parámetros Dinámicos

La configuración se genera automáticamente según los parámetros de CloudFormation:

```
Parámetro    | Por Defecto | Uso en BIND9
─────────────┼─────────────┼──────────────────────────
RedBase      | 26          | Segundo octeto: 10.{RedBase}.x.0/24
NN           | 01          | Tercer octeto: 1{NN}, 2{NN}

Ejemplos:
NN=01, RedBase=26:  10.26.101.0/24, 10.26.201.0/24
NN=05, RedBase=26:  10.26.105.0/24, 10.26.205.0/24
NN=10, RedBase=30:  10.30.110.0/24, 10.30.210.0/24
```

---

## 🔧 Modificar Configuración Post-Deployment

Si necesitas cambiar la configuración **después de desplegar**:

```bash
# 1. Editar el archivo
sudo nano /etc/bind/named.conf.options

# 2. Validar sintaxis
sudo named-checkconf /etc/bind/named.conf.options

# 3. Reiniciar BIND9
sudo systemctl restart bind9

# 4. Verificar
sudo systemctl status bind9

# 5. Ver logs
sudo tail -20 /var/log/syslog | grep named
```

---

## 📂 Estructura de Archivos BIND9

```
/etc/bind/
├── named.conf                    ← Configuración principal
├── named.conf.options            ← ✓ NUEVO - Configurado por UserData
├── named.conf.local              ← Zonas locales
├── named.conf.default-zones      ← Zonas por defecto
├── db.root                        ← Raíces DNS
├── db.127                         ← Zona loopback
└── zones/                         ← Zonas personalizadas (opcional)
```

---

## ⚠️ Consideraciones Importantes

1. **UserData se ejecuta una sola vez**
   - Al lanzar la instancia
   - No se ejecuta si relanzas una instancia existente

2. **Variables de CloudFormation se sustituyen en tiempo de despliegue**
   - `${RedBase}` y `${NN}` se reemplazan ANTES de enviar el UserData
   - Los valores son FIJOS en el archivo generado

3. **Si cambias parámetros NN o RedBase**
   - Necesitas relanzar la instancia (redeploy)
   - O editar manualmente `/etc/bind/named.conf.options`

4. **Cambios manuales se pierden si relanzas la instancia**
   - El UserData generará de nuevo los archivos

---

## 📊 Estadísticas del Cambio

| Métrica | Valor |
|---------|-------|
| Líneas Agregadas | ~29 líneas |
| Líneas Modificadas | 1 línea (cambio de tipo UserData) |
| Cambios Destructivos | 0 (solo adiciones) |
| Recursos Nuevos | 0 (configuración existente) |
| Funcionalidad Afectada | Ubuntu: BIND9 configurable automáticamente |

---

## 🎯 Próximos Pasos

1. ✅ Archivo CloudFormation actualizado
2. → Desplegar la plantilla (create-stack o update-stack)
3. → Esperar a que se lance Ubuntu
4. → Conectar y verificar `/etc/bind/named.conf.options`
5. → Probar resolución DNS desde otra instancia
6. → Verificar logs en `/var/log/syslog`

---

## 📚 Documentación Disponible

| Documento | Propósito |
|-----------|----------|
| **BIND9_Configuration.md** | Guía técnica detallada |
| **BIND9_Resumen_Cambios.txt** | Resumen ejecutivo con ejemplos |
| **00AWSLab01_IPv4_IPv6_2AZ.yaml** | Archivo CloudFormation modificado |

---

## 🔗 Referencias Útiles

- [BIND9 Documentation](https://www.isc.org/bind/)
- [named.conf.options Reference](https://linux.die.net/man/5/named.conf)
- [BIND9 Security Best Practices](https://www.isc.org/bind-security/)

---

## ✨ Resultado Final

✅ BIND9 se configura automáticamente al lanzar Ubuntu  
✅ `/etc/bind/named.conf.options` se crea con la configuración correcta  
✅ Parámetros dinámicos (NN, RedBase) se sustituyen automáticamente  
✅ BIND9 se reinicia automáticamente al final del UserData  
✅ DNS Server está listo para resolver nombres  

🎉 **¡Implementación completada y lista para usar!**

---

*Cambio realizado: 2024-11-20*  
*Archivo: `00AWSLab01_IPv4_IPv6_2AZ.yaml`*  
*Ruta: `C:\Users\javier.teran\Documents\github\AWS_CloudFormation\02AWSLab_IPv4_IPv6_2AZ\`*
