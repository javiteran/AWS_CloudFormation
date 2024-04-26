# :dizzy: Tareas en AWS Academy con AWS CloudFormation

Cuando utilizamos AWS Academy y su learner lab puede interesarnos personalizar el entorno de los alumnos.

Muestra una posible solución de automatización de la creación de entornos de tareas en AWS con AWS CloudFormation.

## :gear: Referencia de comandos AWS CloudFormation

https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/index.html#cli-aws-ec2

## :collision: Configuración del entorno en el Learner Lab

![ConfigurarEntornoLearnerLab.PNG](imagenes/ConfigurarEntornoLearnerLab.PNG)


## Creación del entorno con un parámetro de entrada que será el NN del alumno

```git
git clone https://github.com/javiteran/AWS_CloudFormation.git
cd AWS_CloudFormation
00AWSLab01_dualstack.yaml
```

Con este fichero se creará el siguiente entorno de tareas:

![00AWSCrearVPC_EC2Win_Ubu.PNG](imagenes/00AWSCrearVPC_EC2Win_Ubu.PNG)

Creará:

* Una VPC con Ipv4 e Ipv6
* Dos subredes públicas
* Una puerta de enlace de internet
* La tabla de enrutamiento de las subredes para permitir conectarse a internet
* Un grupo de seguridad para Ubuntu y otro para Windows.
* Se abrirán los puertos 80, 22 y 3389 para Windows y el 53 y 80  para Ubuntu.
* Se permitirá todo el tráfico entre las instancias de la VPC.
* Una instancia EC2 con Windows Server 2022 
* Una instancia EC2 con Ubuntu Server 24.04
* En Ubuntu y Windows se instalarán servicios y roles como DNS para probar la instalación en la creación.
* Direcciones IPs públicas estáticas para las instancias EC2
