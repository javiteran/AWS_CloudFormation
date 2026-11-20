# Ejemplo Visual de Configuración DHCP

## Con Parámetros Por Defecto

```
Parámetro       | Valor Por Defecto | Descripción
-----------------------------------------------------------
Proyecto        | SRI26             | Prefijo del proyecto
NN              | 01                | Número de alumno
RedBase         | 26                | Segundo octeto de la VPC
```

## Configuración Resultante

```
VPC CIDR Block:  10.26.0.0/16
├── Subred Pública 1:     10.26.101.0/24
│   └── Ubuntu Server:    10.26.101.100 (BIND9 DNS)
│
├── Subred Pública 2:     10.26.201.0/24
│   └── Windows Server:   10.26.201.100 (Windows DNS)
│
└── DHCP Option Set:      SRI2601-dhcp-opts
    ├── DomainName:       ec2.internal  (us-east-1)
    ├── DNS Primario:     10.26.101.100 (Ubuntu)
    └── DNS Secundario:   10.26.201.100 (Windows)
```

## Parámetro NN Personalizado (Ejemplo: NN=05)

```
VPC CIDR Block:  10.26.0.0/16
├── Subred Pública 1:     10.26.105.0/24
│   └── Ubuntu Server:    10.26.105.100 (BIND9 DNS)
│
├── Subred Pública 2:     10.26.205.0/24
│   └── Windows Server:   10.26.205.100 (Windows DNS)
│
└── DHCP Option Set:      SRI2605-dhcp-opts
    ├── DomainName:       ec2.internal
    ├── DNS Primario:     10.26.105.100 (Ubuntu)
    └── DNS Secundario:   10.26.205.100 (Windows)
```

## Parámetro RedBase Personalizado (Ejemplo: RedBase=30)

```
VPC CIDR Block:  10.30.0.0/16
├── Subred Pública 1:     10.30.101.0/24
│   └── Ubuntu Server:    10.30.101.100 (BIND9 DNS)
│
├── Subred Pública 2:     10.30.201.0/24
│   └── Windows Server:   10.30.201.100 (Windows DNS)
│
└── DHCP Option Set:      SRI3001-dhcp-opts
    ├── DomainName:       ec2.internal
    ├── DNS Primario:     10.30.101.100 (Ubuntu)
    └── DNS Secundario:   10.30.201.100 (Windows)
```

## Comportamiento del Cliente DHCP

```
┌─────────────────────────────────────────────────────────┐
│ Instancia EC2 inicia o renueva DHCP                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ DHCP Server (AWS)                                        │
│ Responde con DHCP Option Set asociado a la VPC         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Cliente recibe configuración:                            │
│ - Domain Name: ec2.internal                             │
│ - DNS Servers:                                          │
│   * 10.26.101.100 (Ubuntu/BIND9) - PRIMARY              │
│   * 10.26.201.100 (Windows/DNS)  - SECONDARY            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ /etc/resolv.conf en Linux se actualiza:                 │
│ ────────────────────────────────────                    │
│ domain ec2.internal                                     │
│ nameserver 10.26.101.100                                │
│ nameserver 10.26.201.100                                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Resolución DNS de nombres:                              │
│                                                          │
│ $ nslookup example.com                                  │
│ ↓ intenta resolver con 10.26.101.100 (Ubuntu)           │
│ ↓ si no responde, intenta con 10.26.201.100 (Windows)   │
│ ↓ si está configurado, puede hacer forwarding           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Resultado:                                               │
│ ANSWER SECTION:                                         │
│ example.com.    300 IN  A  192.0.2.1                    │
└─────────────────────────────────────────────────────────┘
```

## Configuración de Instancias EC2 en Subredes Distintas

```
┌─────────────────────────────────────┐
│ Subred Pública 1 (10.26.1NN.0/24)  │
├─────────────────────────────────────┤
│ ┌──────────────────────────────────┐│
│ │ Ubuntu Server                    ││
│ │ IP Privada: 10.26.1NN.100       ││
│ │ IP Elástica: 203.0.113.XXX      ││
│ │ Servicios: BIND9 (puerto 53)    ││
│ │ SO: Ubuntu Server                ││
│ └──────────────────────────────────┘│
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Subred Pública 2 (10.26.2NN.0/24)  │
├─────────────────────────────────────┤
│ ┌──────────────────────────────────┐│
│ │ Windows Server 2022              ││
│ │ IP Privada: 10.26.2NN.100       ││
│ │ IP Elástica: 203.0.113.YYY      ││
│ │ Servicios: DNS Role (puerto 53)  ││
│ │ SO: Windows Server 2022          ││
│ └──────────────────────────────────┘│
└─────────────────────────────────────┘

Ambas instancias en diferentes Zonas de Disponibilidad (AZ)
→ Proporciona alta disponibilidad para DNS
```

## Outputs de CloudFormation

Después del despliegue, CloudFormation mostrará:

```
Outputs:
├── VPCId: vpc-0123456789abcdef0
├── VPCCidrIPv4: 10.26.0.0/16
├── VPCCidrIPv6: 2600:1f13:c88:4300::/56
├── SubredPublica1Cidr: 10.26.101.0/24
├── SubredPublica2Cidr: 10.26.201.0/24
├── IPv4Ubuntu: 203.0.113.XXX
├── IPv4Windows: 203.0.113.YYY
├── httpUbuntu: http://203.0.113.XXX
├── httpWindows: http://203.0.113.YYY
├── sshUbuntu: ssh -i vockey.pem ubuntu@203.0.113.XXX
│
├── DHCPOptionSetId: dopt-0abc123def456ghi
├── UbuntuPrivateIp: 10.26.101.100
├── WindowsPrivateIp: 10.26.201.100
└── DHCPDnsServers: 10.26.101.100, 10.26.201.100
```

## Flujo de Creación de Recursos en CloudFormation

```
1. VPC
   ↓
2. IPv6CidrBlock (asociado a VPC)
   ↓
3. SubredPublica1 y SubredPublica2
   ├─→ Esperan IPv6CidrBlock (DependsOn)
   │
4. InternetGateway → VPCGatewayAttachment
   ↓
5. Tabla de Rutas + Rutas
   ↓
6. Asociaciones de Subred a Tabla de Rutas
   ↓
7. DHCP Option Set ← NUEVO RECURSO
   ├─→ Referencia a VPC
   │
8. DHCP Options Association ← NUEVO RECURSO
   ├─→ Asocia DHCP a VPC
   │
9. Grupos de Seguridad (Ubuntu y Windows)
   ↓
10. Instancias EC2 (Ubuntu y Windows)
    ├─→ Subredes especificadas
    ├─→ Grupos de Seguridad
    └─→ Reciben configuración DHCP
   ↓
11. IPs Elásticas (Ubuntu y Windows)
```

## Tabla de Referencias Cruzadas

```
Recurso                 | Referenciado Por              | Línea
─────────────────────────────────────────────────────────────
VPC                     | Múltiples recursos             | 71
IPv6CidrBlock           | SubredPublica1/2 (DependsOn)   | 95
SubredPublica1          | AsociacionSubred1              | 155
SubredPublica2          | AsociacionSubred2              | 159
TablaRutasPublica       | Múltiples routes               | 139-154
InternetGateway         | VPCGatewayAttachment           | 128
                        | Rutas                          | 142, 150
DHCPOptionSet           | DHCPOptionsAssociation         | 180
VPC                     | DHCPOptionsAssociation         | 179
UbuntuSecurityGroup     | UbuntuInstance                 | 211
WindowsSecurityGroup    | WindowsInstance                | 322
UbuntuInstance          | UbuntuElasticIp                | 269
WindowsInstance         | WindowsElasticIp               | 376
```

## Verificación Post-Deployment

```bash
# En cualquier instancia EC2 en la VPC:
$ cat /etc/resolv.conf
domain ec2.internal
nameserver 10.26.101.100
nameserver 10.26.201.100

$ nslookup example.com
Server:         10.26.101.100
Address:        10.26.101.100#53

Non-authoritative answer:
Name:   example.com
Address: 93.184.216.34

# En AWS CLI:
$ aws ec2 describe-dhcp-options-sets --filter Name=association.vpc-id,Values=vpc-xxxxxxxx
{
    "DhcpOptionsSets": [
        {
            "DhcpOptionsId": "dopt-xxxxxxxx",
            "DhcpConfigurations": [
                {
                    "Key": "domain-name-servers",
                    "Values": [
                        {
                            "Value": "10.26.101.100"
                        },
                        {
                            "Value": "10.26.201.100"
                        }
                    ]
                }
            ]
        }
    ]
}
```

---

**Nota:** Todos los ejemplos anteriores usan los parámetros por defecto. Ajusta RedBase y NN según sea necesario.
