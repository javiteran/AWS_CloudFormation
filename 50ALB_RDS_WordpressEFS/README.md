# README para la plantilla de CloudFormation

Este repositorio contiene una plantilla de AWS CloudFormation para crear una infraestructura de red en AWS, que incluye una VPC, subredes públicas y privadas, un Internet Gateway, un NAT Gateway y un sistema de archivos EFS. La plantilla está diseñada para implementar un entorno de WordPress.

## Descripción de la plantilla

La plantilla de CloudFormation realiza las siguientes acciones:

- **Crea una VPC** con un rango CIDR especificado.
- **Crea subredes públicas y privadas** para alojar instancias EC2 y otros recursos.
- **Configura un Internet Gateway** para permitir el acceso a Internet desde las subredes públicas.
- **Configura un NAT Gateway** para permitir que las instancias en subredes privadas accedan a Internet.
- **Crea un sistema de archivos EFS** para almacenamiento compartido entre instancias EC2.

## Parámetros

- **VpcCIDR**: Rango CIDR para la VPC (mínimo /21 para crear 6 subredes /24).
- **WordpressHostHeader**: Nombre de dominio DNS para enrutar tráfico a WordPress.

## Recursos

La plantilla crea los siguientes recursos:
- VPC
- Subredes públicas y privadas
- Internet Gateway
- NAT Gateway
- EFS (Elastic File System)
- Grupos de seguridad para controlar el acceso a los recursos

## Uso

Para utilizar esta plantilla:
1. Clona este repositorio.
2. Abre la consola de AWS CloudFormation.
3. Crea una nueva pila utilizando la plantilla `userdata_cloudwatch_systemmanager_Wordpress_EFS.yaml`.
4. Proporciona los parámetros requeridos.

## Notas

Asegúrate de que los grupos de seguridad y las configuraciones de red estén correctamente configurados para permitir el tráfico necesario para WordPress y otros servicios.
