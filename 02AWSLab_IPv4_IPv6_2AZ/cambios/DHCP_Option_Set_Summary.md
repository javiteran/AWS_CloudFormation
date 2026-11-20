# DHCP Option Set - Resumen de Cambios

## ✅ Cambios Realizados

Se ha añadido un **DHCP Option Set** al archivo `00AWSLab01_IPv4_IPv6_2AZ.yaml` y se ha asociado a la VPC con los siguientes cambios:

### 1. Nueva Sección: Conditions (línea 67)
```yaml
Conditions:
    IsUSEast1: !Equals [!Ref 'AWS::Region', 'us-east-1']
```
- Define una condición para detectar si se está desplegando en la región `us-east-1`
- Usada para configurar el nombre de dominio correcto (AWS trata `us-east-1` de forma especial)

### 2. Nuevo Recurso: DHCPOptionSet (línea 162)
```yaml
DHCPOptionSet:
    Type: AWS::EC2::DHCPOptions
    Properties:
        DomainName: !If
            - IsUSEast1
            - ec2.internal
            - !Sub '${AWS::Region}.compute.internal'
        DomainNameServers:
            - !Sub '10.${RedBase}.1${NN}.100'  # Ubuntu Server
            - !Sub '10.${RedBase}.2${NN}.100'  # Windows Server
        Tags:
            - Key: Name
              Value: !Sub '${Proyecto}${NN}-dhcp-opts'
```

**Características:**
- **DomainName**: Nombre de dominio dinámico según la región
- **DomainNameServers**: Las dos direcciones IP privadas de las instancias EC2
  - **Ubuntu**: `10.{RedBase}.1{NN}.100`
  - **Windows**: `10.{RedBase}.2{NN}.100`

### 3. Nuevo Recurso: DHCPOptionsAssociation (línea 177)
```yaml
DHCPOptionsAssociation:
    Type: AWS::EC2::VPCDHCPOptionsAssociation
    Properties:
        VpcId: !Ref VPC
        DhcpOptionsId: !Ref DHCPOptionSet
```

**Propósito:**
- Asocia el DHCP Option Set a la VPC
- Todas las instancias en la VPC usarán estos servidores DNS

### 4. Nuevos Outputs (líneas 448-460)
Se han añadido 4 nuevos outputs para facilitar la consulta de información:

| Output | Descripción |
|--------|-------------|
| `DHCPOptionSetId` | ID del DHCP Option Set creado |
| `UbuntuPrivateIp` | IP privada de Ubuntu (DNS primario) |
| `WindowsPrivateIp` | IP privada de Windows (DNS secundario) |
| `DHCPDnsServers` | Lista completa de servidores DNS |

## 📋 Parámetros Utilizados

Los servidores DNS se configuran dinámicamente usando los parámetros existentes:
- **`RedBase`**: Segundo octeto de la red (default: 26)
- **`NN`**: Número de alumno (default: 01)

**Ejemplo con valores por defecto:**
- RedBase = 26, NN = 01
- Ubuntu DNS: `10.26.101.100`
- Windows DNS: `10.26.201.100`

## 🔄 Flujo de Resolución DNS

Cuando una instancia en la VPC solicita un nombre de dominio:

1. El cliente DHCP recibe la configuración del Option Set
2. Intenta resolver con el primer DNS (Ubuntu: `10.{RedBase}.1{NN}.100`)
3. Si no responde, usa el segundo DNS (Windows: `10.{RedBase}.2{NN}.100`)
4. Se resuelven nombres de dominio usando BIND9 (en Ubuntu) o DNS de Windows

## ⚠️ Consideraciones Importantes

### Dependencias
- El DHCP Option Set se crea **después** de la VPC
- Se asocia **antes** de que se lancen las instancias
- **Las instancias EC2 ya tienen instalados BIND9 (Ubuntu) y DNS (Windows)** en su UserData

### Timing
- Para que los clientes DHCP reciban la nueva configuración, deberían reiniciar o renovar el DHCP
- En AWS, si lanzas nuevas instancias después de crear el DHCP Option Set, recibirán automáticamente esta configuración

### Validación de Funcionamiento
Para verificar que funciona correctamente:

```bash
# En cualquier instancia EC2 en la VPC:
nslookup example.com 10.26.101.100  # Consultar a Ubuntu
nslookup example.com 10.26.201.100  # Consultar a Windows
cat /etc/resolv.conf                 # Ver configuración del cliente
```

## 📝 Notas Técnicas

- **Tipo**: `AWS::EC2::DHCPOptions` + `AWS::EC2::VPCDHCPOptionsAssociation`
- **Dominio**: dinámico según región (AWS best practice)
- **DNS Primario**: Instancia Ubuntu (BIND9 instalado)
- **DNS Secundario**: Instancia Windows (Rol DNS instalado)
- **Scope**: Aplica a toda la VPC

## ✨ Resultado Final

✅ DHCP Option Set creado y asociado a la VPC
✅ Servidores DNS configurados a las IPs privadas de las dos instancias EC2
✅ Configuración dinámica basada en parámetros de CloudFormation
✅ Outputs para consultar información de la configuración
