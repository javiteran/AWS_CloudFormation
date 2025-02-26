# AWS CloudFormation: ALB, RDS y EC2 Públicas

Este directorio contiene plantillas de AWS CloudFormation para crear una arquitectura que incluye un balanceador de carga de aplicaciones (ALB), una base de datos RDS MySQL y una instancia EC2 pública.

## Archivos

- `09AWS_ALB_EC2Publicas_Export.yaml`: Plantilla para exportar los recursos necesarios.
- `09AWS_RDS_EC2Publicas_Import.yaml`: Plantilla para importar y crear los recursos, incluyendo la base de datos RDS y la instancia EC2.

## Descripción de las Plantillas

### 09AWS_ALB_EC2Publicas_Export.yaml

Esta plantilla exporta los valores necesarios para la configuración de la base de datos y la instancia EC2.

### 09AWS_RDS_EC2Publicas_Import.yaml

Esta plantilla crea los siguientes recursos:

- **Instancia RDS MySQL**: Una base de datos MySQL con las siguientes características:
  - Clase de instancia: `db.t3.micro`
  - Almacenamiento: 20 GB
  - Motor: MySQL 8.0
  - Usuario administrador: `admin`
  - Contraseña: `admin12345`
  - No accesible públicamente
  - Grupo de subredes y grupo de seguridad configurados

- **Instancia EC2 Ubuntu**: Una instancia EC2 con Ubuntu Server 24.04 que actúa como bastión:
  - Tipo de instancia: `t2.micro`
  - AMI: `ami-04b4f1a9cf54c11d0`
  - Grupo de seguridad configurado para permitir SSH
  - Dirección IP elástica asociada
  - Script de usuario para inicializar la base de datos MySQL con datos de prueba

- **Registros DNS en Route53**:
  - Registro A para la instancia EC2 bastión
  - Registro CNAME para la instancia RDS MySQL

## Uso

Para crear el stack, utiliza el siguiente comando:

```sh
aws cloudformation create-stack --stack-name MiStack --template-body file://09AWS_RDS_EC2Publicas_Import.yaml --parameters ParameterKey=NN,ParameterValue=03
```


Para eliminar el stack, utiliza el siguiente comando:

```sh
aws cloudformation delete-stack --stack-name MiStack
```
Para validar la plantilla, utiliza el siguiente comando:

```sh
aws cloudformation validate-template --template-body file://09AWS_RDS_EC2Publicas_Import.yaml
```

Collecting workspace informationClaro, aquí tienes el contenido para el README.md en la carpeta 09ALB_RDS_EC2Publicas:

```markdown
# AWS CloudFormation: ALB, RDS y EC2 Públicas

Este directorio contiene plantillas de AWS CloudFormation para crear una arquitectura que incluye un balanceador de carga de aplicaciones (ALB), una base de datos RDS MySQL y una instancia EC2 pública.

## Archivos

- `09AWS_ALB_EC2Publicas_Export.yaml`: Plantilla para exportar los recursos necesarios.
- `09AWS_RDS_EC2Publicas_Import.yaml`: Plantilla para importar y crear los recursos, incluyendo la base de datos RDS y la instancia EC2.

## Descripción de las Plantillas

### 09AWS_ALB_EC2Publicas_Export.yaml

Esta plantilla exporta los valores necesarios para la configuración de la base de datos y la instancia EC2.

### 09AWS_RDS_EC2Publicas_Import.yaml

Esta plantilla crea los siguientes recursos:

- **Instancia RDS MySQL**: Una base de datos MySQL con las siguientes características:
  - Clase de instancia: `db.t3.micro`
  - Almacenamiento: 20 GB
  - Motor: MySQL 8.0
  - Usuario administrador: `admin`
  - Contraseña: `admin12345`
  - No accesible públicamente
  - Grupo de subredes y grupo de seguridad configurados

- **Instancia EC2 Ubuntu**: Una instancia EC2 con Ubuntu Server 24.04 que actúa como bastión:
  - Tipo de instancia: `t2.micro`
  - AMI: `ami-04b4f1a9cf54c11d0`
  - Grupo de seguridad configurado para permitir SSH
  - Dirección IP elástica asociada
  - Script de usuario para inicializar la base de datos MySQL con datos de prueba

- **Registros DNS en Route53**:
  - Registro A para la instancia EC2 bastión
  - Registro CNAME para la instancia RDS MySQL

## Uso

Para crear el stack, utiliza el siguiente comando:

```sh
aws cloudformation create-stack --stack-name MiStack --template-body file://09AWS_RDS_EC2Publicas_Import.yaml --parameters ParameterKey=NN,ParameterValue=03
```

Para eliminar el stack, utiliza el siguiente comando:

```sh
aws cloudformation delete-stack --stack-name MiStack
```

Para validar la plantilla, utiliza el siguiente comando:

```sh
aws cloudformation validate-template --template-body file://09AWS_RDS_EC2Publicas_Import.yaml
```

## Autor

Javier Teran Gonzalez

## Fecha de Creación

18/02/2025

## Versión

1.20
