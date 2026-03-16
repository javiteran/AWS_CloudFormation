# Transit Gateway para conectar VPCs

## Descripción

Este proyecto crea una arquitectura de red en AWS usando Transit Gateway para conectar múltiples VPCs. Incluye dos templates CloudFormation:

### 1. **15VPCsParaTransitGateway.yaml**
Crea una VPC completa con:
- **VPC** con IPv4 (/16) e IPv6 automático
- **4 Subredes**: 2 públicas y 2 privadas con CIDRs dinámicos (/24)
- **Internet Gateway (IGW)** para tráfico IPv4
- **EgressOnlyInternetGateway (EIGW)** para tráfico IPv6 de salida
- **Tablas de rutas**: una pública y dos privadas
- **Grupo de seguridad**: permite HTTP, HTTPS, SSH, ICMP (IPv4 e IPv6)
- **Instancia EC2 Ubuntu Server 24.04** con:
  - IP pública automática
  - Bind9, Apache2 y PHP preinstalados
  - SSM Agent para Systems Manager
  - Volumen EBS de 20 GB (gp3)

**Parámetro:**
- `NN`: Número de VPC (1-55) - usado para diferenciar VPCs

**Exportaciones:**
- `{StackName}-VPC-ID`: ID de la VPC
- `{StackName}-VPC-Nombre`: Nombre de la VPC
- `{StackName}-PublicSubnet1-ID`: ID de la subnet pública 1
- `{StackName}-PublicSubnet2-ID`: ID de la subnet pública 2
- `{StackName}-PrivateSubnet1-ID`: ID de la subnet privada 1
- `{StackName}-PrivateSubnet2-ID`: ID de la subnet privada 2

### 2. **15TransitGateway.yaml**
Crea el Transit Gateway que conecta dos VPCs:
- **Transit Gateway (TGW)**: enrutador central para conectar VPCs
- **Attachments**: conecta ambas VPCs al TGW (subnets públicas y privadas)

**Parámetros:**
- `Stack1Name`: Nombre del primer stack VPC (ej: tsg-15)
- `Stack2Name`: Nombre del segundo stack VPC (ej: tsg-25)

---

## Instrucciones de Despliegue

### Paso 1: Crear primer VPC
```bash
aws cloudformation create-stack \
  --stack-name vpc-tsg-15 \
  --template-body file://15VPCsParaTransitGateway.yaml \
  --parameters ParameterKey=NN,ParameterValue=15
```

### Paso 2: Crear segunda VPC
```bash
aws cloudformation create-stack \
  --stack-name vpc-tsg-25 \
  --template-body file://15VPCsParaTransitGateway.yaml \
  --parameters ParameterKey=NN,ParameterValue=25
```

### Paso 3: Crear Transit Gateway y conectar ambas VPCs
```bash
aws cloudformation create-stack \
  --stack-name vpc-transit-gateway \
  --template-body file://15TransitGateway.yaml \
  --parameters ParameterKey=Stack1Name,ParameterValue=vpc-tsg-15 \
               ParameterKey=Stack2Name,ParameterValue=vpc-tsg-25
```

---

## Características

✅ **IPv4 e IPv6**: Soporte dual stack en todas las subredes  
✅ **CIDRs dinámicos**: Se calculan automáticamente según la VPC  
✅ **Conectividad**: Transit Gateway para comunicación entre VPCs  
✅ **Seguridad**: Grupos de seguridad pre-configurados  
✅ **Monitoreo**: SSM Agent para Systems Manager Session Manager  
✅ **Automatizado**: Toda la infraestructura con Infrastructure as Code  

---

## Autor
Javier Teran Gonzalez  
Fecha: 16/03/2026  
Versión: 1.0  
Uso: AWS Academy Learning Lab  