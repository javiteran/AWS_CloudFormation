# Creación de una VPC IPv4/IPv6

## Objetivo

El objetivo de este laboratorio es crear una VPC con soporte para IPv4 e IPv6.
También se crearán dos subredes públicas y dos subredes privadas.

Para que todo funcione es necesario crear una puerta de enlace de internet, 
las tablas de enrutamiento y asociar las subredes a las tablas de enrutamiento.

## Recursos utilizados en la creación de una VPC

        Type: AWS::EC2::VPC
        Type: AWS::EC2::VPCCidrBlock
        Type: AWS::EC2::Subnet
        Type: AWS::EC2::InternetGateway
        Type: AWS::EC2::VPCGatewayAttachment
        Type: AWS::EC2::RouteTable
        Type: AWS::EC2::Route
        Type: AWS::EC2::SubnetRouteTableAssociation
