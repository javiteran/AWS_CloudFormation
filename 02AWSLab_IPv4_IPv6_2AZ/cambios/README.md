# ✅ DHCP Option Set - Implementación Completada

## 📋 Resumen Ejecutivo

Se ha **creado exitosamente un DHCP Option Set** en el archivo CloudFormation `00AWSLab01_IPv4_IPv6_2AZ.yaml` con los siguientes características:

### ✨ Lo que se agregó:
1. **DHCP Option Set** con DNS configurados a las IPs privadas de las dos instancias EC2
2. **Asociación a la VPC** para aplicar la configuración a todas las instancias
3. **Outputs** para visualizar la configuración en CloudFormation
4. **Condición** para ajustar el nombre de dominio según la región AWS

---

## 🏗️ Componentes Implementados

### 1. **DHCP Option Set** (`AWS::EC2::DHCPOptions`)
```yaml
DHCPOptionSet:
    Type: AWS::EC2::DHCPOptions
    Properties:
        DomainName: !If [IsUSEast1, ec2.internal, !Sub '${AWS::Region}.compute.internal']
        DomainNameServers:
            - !Sub '10.${RedBase}.1${NN}.100'  # Ubuntu Server (BIND9)
            - !Sub '10.${RedBase}.2${NN}.100'  # Windows Server (DNS Role)
```

**Configuración por defecto:**
- DNS Primario: `10.26.101.100` (Ubuntu)
- DNS Secundario: `10.26.201.100` (Windows)
- Domain Name: `ec2.internal` (us-east-1) o `{REGION}.compute.internal`

### 2. **Asociación a VPC** (`AWS::EC2::VPCDHCPOptionsAssociation`)
```yaml
DHCPOptionsAssociation:
    Type: AWS::EC2::VPCDHCPOptionsAssociation
    Properties:
        VpcId: !Ref VPC
        DhcpOptionsId: !Ref DHCPOptionSet
```

**Efectos:**
- Todas las instancias en la VPC usan estos DNS automáticamente
- Instancias nuevas reciben la configuración al lanzarse
- Instancias existentes pueden necesitar renovar DHCP

### 3. **Outputs para Visualización**
```
DHCPOptionSetId     → ID del DHCP Option Set
UbuntuPrivateIp     → 10.{RedBase}.1{NN}.100
WindowsPrivateIp    → 10.{RedBase}.2{NN}.100
DHCPDnsServers      → Ambas IPs en formato legible
```

---

## 📊 Diagrama de Arquitectura

![DHCP Architecture](../images/image-2de878d37070f743.png)

---

## 🔢 Parámetros de Configuración

| Parámetro | Por Defecto | Uso en DHCP |
|-----------|------------|-----------|
| `RedBase` | 26 | Segundo octeto: `10.26.x.x` |
| `NN` | 01 | Tercer octeto: `10.26.1NN.x` |
| `Proyecto` | SRI26 | Nombre del DHCP: `{Proyecto}{NN}-dhcp-opts` |
| `AWS::Region` | dinámico | Domain Name según región |

**Ejemplo con valores por defecto:**
- VPC: `10.26.0.0/16`
- Ubuntu DNS: `10.26.101.100` → `10.26.1{NN}.100` = `10.26.101.100`
- Windows DNS: `10.26.201.100` → `10.26.2{NN}.100` = `10.26.201.100`

---

## 🚀 Próximos Pasos

### Desplegar la plantilla:
```bash
cd C:\Users\javier.teran\Documents\github\AWS_CloudFormation\02AWSLab_IPv4_IPv6_2AZ

aws cloudformation create-stack \
  --stack-name SRI2601-dhcp-stack \
  --template-body file://00AWSLab01_IPv4_IPv6_2AZ.yaml \
  --parameters \
    ParameterKey=NN,ParameterValue=01 \
    ParameterKey=Proyecto,ParameterValue=SRI26 \
    ParameterKey=RedBase,ParameterValue=26 \
  --region us-east-1
```

### Validar la configuración:
```bash
# Ver configuración DNS en la instancia
cat /etc/resolv.conf

# Probar resolución
nslookup example.com 10.26.101.100
dig @10.26.201.100 google.com
```

---

## 📚 Documentación Incluida

Se han generado 5 documentos de referencia:

| Documento | Propósito |
|-----------|----------|
| **DHCP_Option_Set_Summary.md** | Explicación técnica detallada de los cambios |
| **Validacion_DHCP.md** | Guía completa de validación post-deployment |
| **Cambios_Realizados.txt** | Documento técnico con todas las líneas modificadas |
| **Ejemplo_Visual_DHCP.md** | Ejemplos visuales de configuraciones |
| **Template YAML** | Archivo actualizado con los nuevos recursos |

---

## ✅ Checklist de Validación

- [x] DHCP Option Set creado en CloudFormation
- [x] Asociado correctamente a la VPC
- [x] DNS configurados a IPs privadas de instancias EC2
- [x] Parámetros dinámicos (RedBase, NN)
- [x] Domain Name configurable por región
- [x] Outputs para verificación
- [x] Sintaxis YAML correcta
- [x] Sin cambios destructivos a recursos existentes
- [x] Documentación completa

---

## 🎯 Comportamiento Esperado

### Cuando se despliega la plantilla:
1. ✅ Se crea el DHCP Option Set con 2 servidores DNS
2. ✅ Se asocia a la VPC
3. ✅ Todas las instancias EC2 reciben la configuración
4. ✅ Los servidores DNS (Ubuntu y Windows) comienzan a recibir consultas
5. ✅ Los outputs muestran los IDs y configuración

### Cuando se usa DNS:
1. ✅ Cliente solicita resolución (ej: `nslookup google.com`)
2. ✅ DHCP Client envía consulta a 10.26.101.100 (Ubuntu/BIND9) primero
3. ✅ Si no responde, intenta con 10.26.201.100 (Windows/DNS)
4. ✅ Servidores pueden hacer forwarding a DNS público si es necesario

---

## ⚠️ Notas Importantes

- **Alta Disponibilidad**: Con 2 servidores DNS en diferentes AZs, el servicio es resiliente
- **DNS Forwarding**: Las instancias EC2 están configuradas para hacer forwarding a DNS públicos
- **Domain Name**: Se ajusta automáticamente según la región AWS
- **Timing**: Nuevas instancias lanzadas después reciben la config automáticamente
- **Instancias Existentes**: Pueden necesitar renovar DHCP: `sudo dhclient -r && sudo dhclient`

---

## 📞 Soporte y Referencias

Para más información, consultar:
- **AWS Documentation**: [DHCP Options Sets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_DHCP_Options.html)
- **CloudFormation**: [AWS::EC2::DHCPOptions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-dhcpoptions.html)
- **Linux DNS**: `man resolv.conf`
- **Windows DNS**: Event Viewer → Windows Logs → System

---

## 🎉 ¡Implementación Completada!

El DHCP Option Set ha sido **correctamente agregado y configurado** en tu plantilla CloudFormation. Está listo para ser desplegado en AWS.

✨ **Próximo paso:** Desplega la plantilla y valida el funcionamiento.

---

*Documento generado: 2024-11-20*  
*Archivo: `00AWSLab01_IPv4_IPv6_2AZ.yaml`*  
*Ruta: `C:\Users\javier.teran\Documents\github\AWS_CloudFormation\02AWSLab_IPv4_IPv6_2AZ\`*
