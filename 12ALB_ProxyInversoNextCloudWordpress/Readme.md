# ALB Proxy Inverso - WordPress y NextCloud

## Descripción

Este proyecto despliega una arquitectura AWS completa que utiliza un **Application Load Balancer (ALB)** como proxy inverso para servir **WordPress y NextCloud** en la misma instancia virtual, enrutando el tráfico según el nombre de dominio (host header).

---

## 📋 Componentes Creados

### Infraestructura de Red
- **VPC** con CIDR configurable (mínimo /22)
- **2 Subredes Públicas** - para el ALB
- **2 Subredes Privadas** - para las instancias de aplicación
- **Internet Gateway** - acceso público
- **NAT Gateway** - salida a internet desde subredes privadas (regional, una sola)
- **Tablas de Enrutamiento** - rutas públicas y privadas

### Instancias EC2
- **WordPress** (t3.micro)
  - Ubuntu Server 24.04
  - Apache2 + PHP + módulos necesarios
  - WordPress descargado automáticamente
  - En subred privada (AZ1)

- **NextCloud** (t3.micro)
  - Ubuntu Server 24.04
  - Apache2 + PHP + módulos necesarios
  - NextCloud descargado automáticamente
  - En subred privada (AZ2)

### Balanceo y Enrutamiento
- **ALB (Application Load Balancer)**
  - Internet-facing en subredes públicas
  - Escuchando en puerto 80 (HTTP)
  - Grupo de seguridad abierto a 0.0.0.0/0

- **Target Groups**
  - Uno para WordPress
  - Uno para NextCloud
  - Health checks configurados

- **Listener Rules** (Host Header Based Routing)
  - `wp1.alisal01.com.es` → WordPress
  - `nc1.alisal01.com.es` → NextCloud

### Monitoreo y Agentes
- **CloudWatch Agent** instalado en ambas instancias
  - Recopila logs de syslog
  - Recopila logs de Apache2 (access y error)
  - Envía a CloudWatch Logs

- **SSM Agent** para Systems Manager Session Manager
  - Acceso sin key pair necesario

---

## 📊 Arquitectura

```
┌─────────────────────── INTERNET ──────────────────────┐
│                                                         │
└────────────────────────────┬────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │      ALB        │
                    │  (HTTP Puerto 80)│
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                                  │
    ┌───────▼────────┐            ┌──────────▼───────┐
    │ WordPress      │            │ NextCloud        │
    │ (AZ1, Privada) │            │ (AZ2, Privada)   │
    │ Port 80        │            │ Port 80          │
    └────────┬───────┘            └──────────┬───────┘
             │                               │
             └───────────────┬───────────────┘
                             │
                    ┌────────▼────────┐
                    │  NAT Gateway    │
                    │  (Regional)     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Internet Gateway│
                    │  (Para ALB)     │
                    └─────────────────┘
```

---

## 🔧 Parámetros

| Parámetro | Descripción | Valor por defecto |
|-----------|-------------|-------------------|
| `VpcCIDR` | Rango CIDR para la VPC (mínimo /22) | `10.26.0.0/22` |
| `WordpressHostHeader` | Nombre de dominio para WordPress | `wp1.alisal01.com.es` |
| `NextCloudHostHeader` | Nombre de dominio para NextCloud | `nc1.alisal01.com.es` |

---

## 🚀 Despliegue

### Paso 1: Crear el Stack

```bash
aws cloudformation create-stack \
  --stack-name alb-proxy-wordpress-nextcloud \
  --template-body file://12ALB_NextCloud_Worpress.yaml \
  --parameters \
    ParameterKey=VpcCIDR,ParameterValue=10.26.0.0/22 \
    ParameterKey=WordpressHostHeader,ParameterValue=wp1.alisal01.com.es \
    ParameterKey=NextCloudHostHeader,ParameterValue=nc1.alisal01.com.es \
  --capabilities CAPABILITY_NAMED_IAM
```

### Paso 2: Esperar a que se complete

```bash
aws cloudformation wait stack-create-complete \
  --stack-name alb-proxy-wordpress-nextcloud
```

### Paso 3: Configurar DNS

Obtén el DNS del ALB:
```bash
aws cloudformation describe-stacks \
  --stack-name alb-proxy-wordpress-nextcloud \
  --query 'Stacks[0].Outputs[?OutputKey==`ApplicationLoadBalancerURL`].OutputValue' \
  --output text
```

Añade en tu proveedor DNS:
```
wp1.alisal01.com.es    CNAME   <ALB-DNS-NAME>
nc1.alisal01.com.es    CNAME   <ALB-DNS-NAME>
```

---

## 📦 Capacidades Requeridas

- `CAPABILITY_NAMED_IAM` - Requerido para crear IAM roles

---

## 🔐 Grupos de Seguridad

### ALB Security Group
- **Ingreso:**
  - Puerto 80 (HTTP) desde 0.0.0.0/0
  - Puerto 443 (HTTPS) desde 0.0.0.0/0
- **Egreso:** Todo permitido

### WordPress Security Group
- **Ingreso:**
  - Puerto 80 solo desde ALB Security Group
- **Egreso:** Todo permitido

### NextCloud Security Group
- **Ingreso:**
  - Puerto 80 solo desde ALB Security Group
- **Egreso:** Todo permitido

---

## 📍 Ubicaciones de los Recursos

### Subredes Públicas (ALB)
- PublicSubnet1: /24 en AZ1
- PublicSubnet2: /24 en AZ2

### Subredes Privadas (EC2)
- PrivateSubnet1: /24 en AZ1 (WordPress)
- PrivateSubnet2: /24 en AZ2 (NextCloud)

**Cálculo automático de CIDR:** Las subredes se derivan del VPC CIDR usando `Fn::Cidr`

---

## 💾 Bases de Datos

⚠️ **Nota:** Este template **NO incluye RDS**. Ambas aplicaciones necesitan una base de datos:

**Opciones:**
1. **Crear RDS por separado** (MySQL o PostgreSQL)
2. **Usar una base de datos pre-existente**
3. **Añadir RDS al template** (modificación futura)

---

## 📝 Logs y Monitoreo

### CloudWatch Logs
Las instancias envían logs a:
- Log Group: `/ec2/ubuntu24`
- Log Streams:
  - `{instance-id}` - logs del sistema (syslog)
  - `{instance-id}-apache-access` - logs de acceso Apache
  - `{instance-id}-apache-error` - logs de error Apache

### Systems Manager Session Manager
Accede sin key pair:
```bash
aws ssm start-session --target i-<instance-id>
```

---

## 🔥 Configuración de HTTPS (Opcional)

Para añadir HTTPS (443):

1. **Obtén certificados en ACM** para ambos dominios
2. **Crea un nuevo Listener en puerto 443**
3. **Añade los certificados al Listener**
4. **Crea ListenerRules para HTTPS**
5. **Redirige 80 → 443** (modificar DefaultAction del Listener en 80)

---

## 📤 Outputs

El stack proporciona:

| Output | Descripción |
|--------|-------------|
| `VPCCidr` | CIDR de la VPC creada |
| `ApplicationLoadBalancerURL` | DNS público del ALB |
| `DNSRegistroWordpress` | Comando para registrar WordPress en DNS |
| `DNSRegistroNextCloud` | Comando para registrar NextCloud en DNS |
| `InstanceIdWordpress` | ID de la instancia WordPress |
| `InstanceIdNextCloud` | ID de la instancia NextCloud |
| `URLWordpress` | URL de acceso a WordPress |
| `URLNextCloud` | URL de acceso a NextCloud |

---

## 🗑️ Eliminación

Para eliminar el stack y todos sus recursos:

```bash
aws cloudformation delete-stack \
  --stack-name alb-proxy-wordpress-nextcloud
```

---

## ✨ Características Destacadas

✅ **Proxy Inverso** - Un ALB enruta a dos aplicaciones diferentes  
✅ **Host-based Routing** - Enrutamiento según número de dominio  
✅ **Alta Disponibilidad** - Distribuido en 2 AZs  
✅ **Seguridad** - Instancias en subredes privadas, NAT para salida  
✅ **Monitoreo** - CloudWatch Logs y SSM Agent preinstalados  
✅ **Automatización Total** - CloudFormation UserData instala todo  
✅ **Escalable** - Fácil añadir más dominios/aplicaciones  

---

## 📚 Información del Autor

- **Autor:** Javier Teran Gonzalez
- **Fecha creación:** 12/2024
- **Versión:** 1.0
- **Uso:** AWS Academy Learning Lab

---

## 🆘 Troubleshooting

### Las instancias no reciben tráfico
- Verifica que los Security Groups del ALB y las instancias estén vinculados correctamente
- Revisa en EC2 → Target Groups → Health Checks

### No resuelven los dominios
- Asegúrate de que los registros CNAME apunten al DNS del ALB
- Usa `nslookup` o `dig` para verificar: `nslookup wp1.alisal01.com.es`

### Acceso a las instancias
- Usa Systems Manager Session Manager: `aws ssm start-session --target <instance-id>`
- Alternativamente, usa un bastion host en la subred pública

