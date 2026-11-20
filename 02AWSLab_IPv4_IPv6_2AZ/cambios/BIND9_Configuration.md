# Configuración de BIND9 - named.conf.options

## 📝 Cambio Realizado

Se ha modificado el **UserData de la instancia Ubuntu** para configurar automáticamente el archivo `/etc/bind/named.conf.options` durante el lanzamiento de la instancia.

## 🔧 Configuración Agregada

El script UserData ahora crea y configura el archivo `/etc/bind/named.conf.options` con el siguiente contenido:

```bash
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";

    // Habilitar la recursión
    recursion yes;

    // Permitir la recursión solo a tu red local o a la IP del Windows Server
    allow-recursion {
        localhost;
        10.${RedBase}.1${NN}.0/24;
        10.${RedBase}.2${NN}.0/24;
    };

    // Opcional pero recomendado: Añadir forwarders hacia DNS públicos (ej. Google o Cloudflare)
    //forwarders {
    //    8.8.8.8;
    //    1.1.1.1;
    //};

    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# Reiniciar BIND9
systemctl restart bind9
```

## 📍 Ubicación en el archivo YAML

**Archivo**: `00AWSLab01_IPv4_IPv6_2AZ.yaml`  
**Recurso**: `UbuntuInstance`  
**Sección**: `UserData`  
**Líneas**: 277-312 (aproximadamente)

## ⚙️ Detalles de la Configuración

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `directory` | `/var/cache/bind` | Directorio de caché de BIND9 |
| `recursion` | `yes` | Habilita resolución recursiva de nombres |
| `allow-recursion` | localhost, 10.{RedBase}.1{NN}.0/24, 10.{RedBase}.2{NN}.0/24 | Redes que pueden hacer consultas recursivas |
| `dnssec-validation` | `auto` | Validación automática de DNSSEC |
| `listen-on` | `any` | Escucha en todas las interfaces IPv4 |
| `listen-on-v6` | `any` | Escucha en todas las interfaces IPv6 |

## 📊 Parámetros Dinámicos

La configuración utiliza **variables de CloudFormation** que se reemplazan durante el despliegue:

```
10.${RedBase}.1${NN}.0/24  → Red de Subred Pública 1 (Ubuntu)
10.${RedBase}.2${NN}.0/24  → Red de Subred Pública 2 (Windows)
```

**Ejemplo con valores por defecto (RedBase=26, NN=01):**
```
allow-recursion {
    localhost;
    10.26.101.0/24;  ← Subred Ubuntu
    10.26.201.0/24;  ← Subred Windows
};
```

## 🚀 Comportamiento Post-Deployment

Cuando se lance la instancia Ubuntu:

1. ✅ Se instala BIND9 (`apt-get install bind9 -y`)
2. ✅ Se crea el archivo `/etc/bind/named.conf.options`
3. ✅ Se configura con los valores correctos basados en parámetros
4. ✅ Se reinicia BIND9 (`systemctl restart bind9`)
5. ✅ BIND9 está listo para resolver nombres

## 🔐 Seguridad

### allow-recursion
- **localhost**: BIND9 puede consultar a sí mismo
- **10.{RedBase}.1{NN}.0/24**: Instancias en la subred Ubuntu pueden hacer consultas
- **10.{RedBase}.2{NN}.0/24**: Instancias en la subred Windows pueden hacer consultas

Esto evita que el servidor DNS sea explotado por recursión desde Internet.

## 💡 Opciones Comentadas

### Forwarders (comentado por defecto)
```bash
//forwarders {
//    8.8.8.8;      ← Google DNS
//    1.1.1.1;      ← Cloudflare DNS
//};
```

**Para habilitar forwarding a DNS públicos:**
1. Descomenta las líneas
2. Reemplaza o añade los DNS públicos deseados
3. Redeploy la instancia

## 📝 Verificación Post-Deployment

### Conectar a la instancia Ubuntu:
```bash
ssh -i vockey.pem ubuntu@<ELASTIC_IP>
```

### Verificar la configuración:
```bash
# Ver el archivo
cat /etc/bind/named.conf.options

# Verificar que BIND9 está corriendo
sudo systemctl status bind9

# Ver logs
sudo tail -f /var/log/syslog | grep named

# Verificar puerto 53
sudo netstat -tlnp | grep :53
```

### Probar resolución DNS:
```bash
# Desde otra instancia o cliente
nslookup google.com 10.26.101.100
dig @10.26.101.100 example.com

# O desde la misma instancia Ubuntu
nslookup localhost
```

## 🔄 Cambios Realizar Manualmente

Si necesitas cambiar la configuración **después de desplegar**, puedes:

### 1. Editar el archivo directamente:
```bash
sudo nano /etc/bind/named.conf.options
```

### 2. Validar la sintaxis:
```bash
sudo named-checkconf /etc/bind/named.conf.options
```

### 3. Reiniciar BIND9:
```bash
sudo systemctl restart bind9
```

### 4. Verificar estado:
```bash
sudo systemctl status bind9
```

## 📋 Archivos Relacionados en BIND9

```
/etc/bind/
├── named.conf                    ← Configuración principal (no modificado)
├── named.conf.options            ← ✓ NUEVO - Configurado por UserData
├── named.conf.local              ← Zonas locales (no modificado)
├── named.conf.default-zones      ← Zonas por defecto (no modificado)
├── db.root                        ← Raíces DNS (no modificado)
└── zones/                         ← Zonas personalizadas (opcional)
```

## 🎯 Próximas Acciones

1. ✅ Desplegar la plantilla CloudFormation actualizada
2. ✅ Esperar a que se lance la instancia Ubuntu
3. ✅ Verificar que `/etc/bind/named.conf.options` existe
4. ✅ Verificar que BIND9 está corriendo
5. ✅ Probar resolución DNS desde otra instancia

## ⚠️ Notas Importantes

- **CloudFormation Substitution**: Las variables `${RedBase}` y `${NN}` se reemplazan **durante el UserData**
- **Reinicio**: BIND9 se reinicia automáticamente al final del UserData
- **Tiempo**: El UserData se ejecuta una sola vez al lanzar la instancia
- **Cambios Posteriores**: Si modificas el archivo manualmente, **NO se sincroniza** si relanzas la instancia (tendrías que redeploy)

## 📚 Referencias

- [BIND9 Documentation](https://www.isc.org/bind/)
- [named.conf.options Reference](https://linux.die.net/man/5/named.conf)
- [BIND9 Security](https://www.isc.org/bind-security/)

---

**Cambio realizado**: 2024-11-20  
**Archivo modificado**: `00AWSLab01_IPv4_IPv6_2AZ.yaml`  
**Componente**: UbuntuInstance UserData
