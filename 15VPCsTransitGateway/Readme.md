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

## TransitGateway Peering

Si quiero conectar VPCs en diferentes regiones, puedo usar Transit Gateway Peering. Esto permite que Transit Gateways en distintas regiones se comuniquen entre sí, facilitando la conexión de VPCs globalmente sin necesidad de VPN o conexiones directas.


*El Transit Gateway (TGW) Peering es una solución avanzada que te permite conectar dos Transit Gateways que residen en cuentas (o regiones) diferentes sin necesidad de AWS Resource Access Manager.*

Para conectar 3 cuentas (Cuenta A, Cuenta B y Cuenta C) usando este método, el diseño sería el siguiente:

* La Arquitectura (Topología de Estrella o Malla)
* Debes crear un Transit Gateway en cada cuenta. Luego, estableces "Peering Attachments" entre ellos.


1. Cuenta A: Crea TGW-A y conéctalo a sus propias VPCs mediante  VPC Attachment.

2. Cuenta B: Crea TGW-B y conéctalo a sus propias VPCs.

### Paso a Paso para el "Hack" del Peering
#### 1. Crear la solicitud de Peering (Desde Cuenta A)
Ve a la consola de VPC > Transit Gateway Attachments y haz clic en Create transit gateway attachment:

1. Transit Gateway ID: Selecciona tu TGW-A.

2. Attachment type: Elige Peering Connection.

3. Account: Selecciona Remote account e ingresa el ID de la Cuenta B.

4. Region: Selecciona la región donde esté el otro TGW (aunque sea la misma).

5. Transit Gateway (Acceptor): Ingresa el ID del TGW-B (tendrás que pedírselo al compañero o copiarlo de tu otra sesión).

#### 2. Aceptar la solicitud (En Cuenta B)
En la Cuenta B, ve a Transit Gateway Attachments. Verás una conexión con estado pending-acceptance. Selecciónala y dale a Actions > Accept transit gateway attachment.


#### 3. El verdadero reto: El Enrutamiento (Routing)
Aquí es donde la mayoría falla. El tráfico no fluirá solo porque el peering esté "Available". Tienes que configurar tres capas de rutas:

* En la VPC (Cuenta A): Tu tabla de rutas de la subred debe decir: "Para ir a la IPs de la Cuenta B, sal por el tgw-A".

* En el TGW-A (Cuenta A): Debes ir a Transit Gateway Route Tables y añadir una ruta estática: "Para ir a las IPs de la Cuenta B, usa el peering-attachment que creamos".

* En el TGW-B (Cuenta B): Debes hacer lo mismo a la inversa para que el tráfico sepa volver.

---

## Autor
Javier Teran Gonzalez  
Fecha: 16/03/2026  
Versión: 1.0  
Uso: AWS Academy Learning Lab  