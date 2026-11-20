# Validación de la Configuración DHCP

## 🎯 Verificación Post-Deployment

Después de desplegar la plantilla CloudFormation, puedes validar que el DHCP Option Set está correctamente configurado con los siguientes pasos:

### 1. Verificar desde AWS Console
```
VPC → DHCP Options Sets
→ Busca el set con nombre: {Proyecto}{NN}-dhcp-opts
→ Verifica Domain Name Servers:
   - 10.{RedBase}.1{NN}.100
   - 10.{RedBase}.2{NN}.100
```

### 2. Verificar Asociación a la VPC
```
VPC → Your VPCs
→ Selecciona tu VPC {Proyecto}{NN}-vpc
→ Acciones → Edit DHCP Options Set
→ Verifica que esté asociado el DHCP Options Set correcto
```

### 3. Desde la Terminal (SSH a cualquier instancia EC2)

#### Ver configuración DNS del cliente
```bash
cat /etc/resolv.conf
# Deberías ver:
# nameserver 10.{RedBase}.1{NN}.100
# nameserver 10.{RedBase}.2{NN}.100
```

#### Verificar DHCP lease
```bash
# En Ubuntu
grep DHCP /var/log/syslog | tail -20

# En Windows (PowerShell)
Get-NetIPConfiguration
```

#### Test de resolución DNS

**Consultar al primer DNS (Ubuntu/BIND9):**
```bash
nslookup google.com 10.{RedBase}.1{NN}.100
dig @10.{RedBase}.1{NN}.100 google.com

# Respuesta esperada: OK (aunque sea forward hacia DNS público)
```

**Consultar al segundo DNS (Windows):**
```bash
nslookup google.com 10.{RedBase}.2{NN}.100
dig @10.{RedBase}.2{NN}.100 google.com

# Respuesta esperada: OK (aunque sea forward hacia DNS público)
```

#### Verificar si BIND9 está corriendo (en Ubuntu)
```bash
sudo systemctl status bind9
# Debería mostrar: active (running)

sudo netstat -tlnp | grep :53
# Debería mostrar puerto 53 escuchando
```

#### Verificar si DNS de Windows está corriendo
```powershell
# En Windows (PowerShell)
Get-Service DNS
# Debería mostrar: Running

netstat -an | findstr :53
# Debería mostrar puerto 53 escuchando
```

---

## 🔍 Troubleshooting

### Problema: Las instancias no reciben la configuración DHCP

**Solución 1:** Renovar DHCP
```bash
# Ubuntu
sudo dhclient -r
sudo dhclient

# Windows (PowerShell como Admin)
ipconfig /release
ipconfig /renew
```

**Solución 2:** Reiniciar instancias
```bash
# Desde AWS CLI
aws ec2 reboot-instances --instance-ids i-xxxxxxxxx
```

### Problema: DNS no resuelve nombres

**Verificación:**
1. ¿BIND9 está corriendo en Ubuntu? `sudo systemctl status bind9`
2. ¿DNS Role está activo en Windows? `Get-Service DNS`
3. ¿Hay reglas de firewall bloqueando puerto 53?

**Solución:**
- Habilitar puertos 53/TCP y 53/UDP en Security Groups
- Verificar reglas de grupo de seguridad en AWS Console

### Problema: Solo resuelve a través de un servidor DNS

**Verificación:**
```bash
# Ver qué DNS está respondiendo
dig +trace google.com
```

**Solución:**
- Verificar que ambas instancias tengan los servicios DNS activos
- Revisar logs de BIND9: `/var/log/syslog`
- Revisar logs de Windows DNS: Event Viewer → Windows Logs

---

## 📊 Validación Automatizada

### Script para validar configuración (ejecutar en instancia EC2 Ubuntu)

```bash
#!/bin/bash
echo "=== Validación DHCP Option Set ==="

# 1. Verificar resolv.conf
echo -e "\n1. Configuración DNS:"
cat /etc/resolv.conf | grep nameserver

# 2. Verificar BIND9
echo -e "\n2. Estado de BIND9:"
sudo systemctl is-active bind9

# 3. Test de resolución
echo -e "\n3. Test de resolución DNS (Primary):"
dig +short @10.26.101.100 google.com 2>&1 | head -1

echo -e "\n4. Test de resolución DNS (Secondary):"
dig +short @10.26.201.100 google.com 2>&1 | head -1

# 5. Verificar puerto 53
echo -e "\n5. Puerto 53 escuchando:"
sudo netstat -tlnp 2>/dev/null | grep :53

echo -e "\n=== Validación Completada ==="
```

### Script para validar (ejecutar en instancia EC2 Windows)

```powershell
# PowerShell como Administrator
Write-Host "=== Validacion DHCP Option Set ==="

# 1. Verificar configuracion DNS
Write-Host "`n1. Configuracion DNS:"
Get-NetIPConfiguration | Select-Object InterfaceAlias, DNSServer

# 2. Verificar servicio DNS
Write-Host "`n2. Estado de DNS Service:"
Get-Service DNS | Select-Object Status, Name

# 3. Test de resolucion (Primary)
Write-Host "`n3. Test de resolucion DNS (Primary):"
Resolve-DnsName -Server 10.26.101.100 -Name google.com -ErrorAction SilentlyContinue

# 4. Test de resolucion (Secondary)
Write-Host "`n4. Test de resolucion DNS (Secondary):"
Resolve-DnsName -Server 10.26.201.100 -Name google.com -ErrorAction SilentlyContinue

Write-Host "`n=== Validacion Completada ==="
```

---

## ✅ Checklist Final

- [ ] DHCP Option Set está creado en AWS Console
- [ ] DHCP Option Set está asociado a la VPC correcta
- [ ] DomainNameServers contiene 2 IPs: Ubuntu y Windows
- [ ] Instancias EC2 reciben configuración DHCP (ver `/etc/resolv.conf`)
- [ ] BIND9 está corriendo en Ubuntu (port 53/TCP)
- [ ] DNS Role está activo en Windows (port 53/TCP)
- [ ] Security Groups permiten puerto 53/TCP y 53/UDP
- [ ] `nslookup` resuelve nombres exitosamente
- [ ] Ambos servidores DNS responden consultas

---

## 📝 Notas Importantes

1. **Timing**: Nuevas instancias lanzadas DESPUÉS de crear el DHCP Option Set recibirán automáticamente la configuración.

2. **Instancias Existentes**: Si lanzaste instancias ANTES del DHCP Option Set, necesitas renovar DHCP o reiniciar.

3. **DNS Forwarding**: Como las instancias EC2 típicamente usan solo DNS público, los servicios BIND9 y Windows DNS están configurados para hacer forwarding a DNS públicos.

4. **Domain Name**: Se configura automáticamente según la región:
   - `us-east-1`: `ec2.internal`
   - Otras regiones: `{REGION}.compute.internal`

5. **Alta Disponibilidad**: Con dos servidores DNS, si uno falla, el cliente automáticamente usa el otro.
