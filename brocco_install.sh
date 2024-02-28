#!/bin/bash

# Ruta del archivo a verificar
archivo="/etc/ssh/sshd_config.d/50-cloud-init.conf"
archivo_sysctl="/etc/sysctl.conf"
archivo_rc_local="/etc/rc.local"

# Verificar si el archivo existe y tiene contenido
if [ -e "$archivo" ] && [ -s "$archivo" ]; then
    # Mostrar el contenido antes de borrarlo (opcional)
    # Borrar el contenido del archivo
    echo -n > "$archivo"

    echo "Contenido de $archivo después de borrar:"
    cat "$archivo"

    echo "Contenido borrado exitosamente."
else
    echo "El archivo $archivo no existe o está vacío. No se realizaron cambios."
fi

# Agregar contenido a /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee -a "$archivo_sysctl"
echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee -a "$archivo_sysctl"
echo "net.ipv6.conf.lo.disable_ipv6=1" | sudo tee -a "$archivo_sysctl"
echo "Contenido agregado a $archivo_sysctl"

# Crear y agregar contenido a /etc/rc.local
echo "#!/bin/bash" | sudo tee "$archivo_rc_local"
echo "# /etc/rc.local" | sudo tee -a "$archivo_rc_local"
echo "" | sudo tee -a "$archivo_rc_local"
echo "/etc/sysctl.d" | sudo tee -a "$archivo_rc_local"
echo "/etc/init.d/procps restart" | sudo tee -a "$archivo_rc_local"
echo "sysctl -p" | sudo tee -a "$archivo_rc_local"
echo "exit 0" | sudo tee -a "$archivo_rc_local"
echo "Contenido agregado a $archivo_rc_local"

# Dar permisos de ejecución a /etc/rc.local
sudo chmod +x "$archivo_rc_local"
echo "Permisos de ejecución concedidos a $archivo_rc_local"



#Docker repo

# Crear directorio /etc/apt/keyrings
sudo install -m 0755 -d /etc/apt/keyrings
if [ $? -eq 0 ]; then
    echo "Directorio /etc/apt/keyrings creado satisfactoriamente."
else
    echo "Error al crear el directorio /etc/apt/keyrings. Cancelando el proceso."
    exit 1
fi

# Descargar la clave GPG de Docker y configurar apt. Si existe, overwrite.

# Determinar la distribución de Linux
if [ -e /etc/os-release ]; then
    source /etc/os-release
    case $ID in
        centos)
            os_type="centos";;
        debian)
            os_type="debian";;
        fedora)
            os_type="fedora";;
        raspbian)
            os_type="raspbian";;
        rhel)
            os_type="rhel";;
        sles)
            os_type="sles";;
        ubuntu)
            os_type="ubuntu";;
        *)
            echo "Distribución de Linux no reconocida. Cancelando el proceso."
            exit 1;;
    esac
else
    echo "No se pudo determinar la distribución de Linux. Cancelando el proceso."
    exit 1
fi

# Construir la URL de Docker
docker_url="https://download.docker.com/linux/$os_type/gpg"

# Descargar la clave GPG de Docker y configurar apt
curl -fsSL $docker_url | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

if [ $? -eq 0 ]; then
    echo "Clave GPG de Docker descargada y configurada satisfactoriamente."
else
    echo "Error al descargar la clave GPG de Docker. Cancelando el proceso."
    exit 1
fi

# Agregar repositorio de Docker a /etc/apt/sources.list.d/docker.list

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $docker_url $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

if [ $? -eq 0 ]; then
    echo "Repositorio de Docker agregado satisfactoriamente a /etc/apt/sources.list.d/docker.list."
else
    echo "Error al agregar el repositorio de Docker. Cancelando el proceso."
    exit 1
fi

# Actualizar apt
sudo apt-get update
if [ $? -eq 0 ]; then
    echo "Apt actualizado satisfactoriamente."
else
    echo "Error al actualizar apt. Cancelando el proceso."
    exit 1
fi

# Instalar paquetes adicionales
sudo apt install python3-pip default-jre git cmake apt-transport-https ca-certificates curl software-properties-common jq zip awscli docker.io docker-compose -y
if [ $? -eq 0 ]; then
    echo "Paquetes adicionales instalados satisfactoriamente."
else
    echo "Error al instalar paquetes adicionales. Cancelando el proceso."
    exit 1
fi

echo "Proceso completado exitosamente."


# Instalar AWS Greengrass
echo "Instalando AWS Greengrass Agent"

# Crear directorio /greengrass/install
sudo mkdir -p /greengrass/install
if [ $? -eq 0 ]; then
    echo "Directorio /greengrass/install creado satisfactoriamente."
else
    echo "Error al crear el directorio /greengrass/install. Cancelando el proceso."
    exit 1
fi

# Cambiar al directorio /greengrass/install
cd /greengrass/install

# Descargar e instalar AWS Greengrass Nucleus
#sudo su
sudo curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-nucleus-latest.zip > greengrass-nucleus-latest.zip && unzip greengrass-nucleus-latest.zip -d GreengrassInstaller
if [ $? -eq 0 ]; then
    echo "AWS Greengrass Nucleus descargado e instalado satisfactoriamente."
else
    echo "Error al descargar o instalar AWS Greengrass Nucleus. Cancelando el proceso."
    exit 1
fi

# Clonar el repositorio de AWS Greengrass Labs Component
sudo git clone https://github.com/awslabs/aws-greengrass-labs-component-for-home-assistant.git
cd aws-greengrass-labs-component-for-home-assistant/

# Modificar requirements.txt
sed 's/==.*//' requirements.txt >> reque.txt && mv requirements.txt requirements.txtORI && mv reque.txt requirements.txt
sudo pip3 install -r requirements.txt --break-system-packages
if [ $? -eq 0 ]; then
    echo "Repositorio de AWS Greengrass Labs Component clonado y requerimientos instalados satisfactoriamente."
else
    echo "Error al clonar el repositorio o instalar requerimientos. Cancelando el proceso."
    exit 1
fi


# Obtener el nombre del host del servidor
default_thing_name=$(hostname)

echo "#"
echo "#"
echo "#"
echo "#"
# Solicitar datos al usuario con valores por defecto
read -p "Ingrese el nombre de la cosa de AWS (presione Enter para el valor por defecto '$default_thing_name'): " AWS_THING_NAME

export AWS_THING_NAME=${AWS_THING_NAME:-$default_thing_name}

read -p "Ingrese la región de AWS (presione Enter para el valor por defecto 'us-west-2'): " AWS_REGION_NAME

export AWS_REGION_NAME=${AWS_REGION_NAME:-us-west-2}

# Solicitar la clave de acceso de AWS de forma segura (sin mostrar en la salida)
read -sp "Ingrese la clave de acceso de AWS (no se mostrara el valor ingresado): " AWS_ACCESS_KEY_ID

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}
echo

# Solicitar la clave secreta de AWS de forma segura (sin mostrar en la salida)
read -sp "Ingrese la clave secreta de AWS (no se mostrara el valor ingresado): " AWS_SECRET_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}
echo

# Imprimir valores ingresados o por defecto (excepto las claves)
echo "AWS_THING_NAME: $AWS_THING_NAME"
echo "AWS_REGION_NAME: $AWS_REGION_NAME"

echo "Proceso completado exitosamente."


# Cambiar al directorio /greengrass/install
cd /greengrass/install

# Ejecutar el comando para instalar Greengrass
sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE -jar ./GreengrassInstaller/lib/Greengrass.jar \
--aws-region $AWS_REGION_NAME --thing-name $AWS_THING_NAME --component-default-user ggc_user:ggc_group \
--provision true --setup-system-service true --deploy-dev-tools true

# Verificar el resultado del comando anterior
if [ $? -eq 0 ]; then
    echo "AWS Greengrass instalado satisfactoriamente."
else
    echo "Error al instalar AWS Greengrass. Cancelando el proceso."
    exit 1
fi

# Crear directorio /greengrass/install/Deployment
mkdir -p /greengrass/install/Deployment

# Definir la variable AWS_ARN_IOT_THING
AWS_ARN_IOT_THING="arn:aws:iot:$AWS_REGION_NAME:043844131101:thing/$AWS_THING_NAME"

# Crear el archivo greengrassDeploy.json.template
echo '
{
    "targetArn": ,
    "deploymentName": "Deployment of Brocco Hub",
    "components": {
        "aws.greengrass.Cli": {
            "componentVersion": "2.12.1"
        },
        "aws.greengrass.DockerApplicationManager": {
            "componentVersion": "2.0.11"
        },
        "aws.greengrass.LocalDebugConsole": {
            "componentVersion": "2.4.1"
        },
        "aws.greengrass.Nucleus": {
            "componentVersion": "2.12.1"
        },
        "aws.greengrass.SecretManager": {
            "componentVersion": "2.1.7",
            "configurationUpdate": {
                "merge": "{\"cloudSecrets\":[{\"arn\":\"arn:aws:secretsmanager:us-west-2:043844131101:secret:greengrass-home-assistant-QXMfEA\"}]}"
            },
            "runWith": {}
        },
        "aws.greengrass.SecureTunneling": {
            "componentVersion": "1.0.18"
        },
        "aws.greengrass.clientdevices.Auth": {
            "componentVersion": "2.4.5",
            "configurationUpdate": {
                "merge": "{\"deviceGroups\":{\"formatVersion\":\"2021-03-05\",\"definitions\":{\"MyPermissiveDeviceGroup\":{\"selectionRule\":\"thingName: *\",\"policyName\":\"MyPermissivePolicy\"}},\"policies\":{\"MyPermissivePolicy\":{\"AllowAll\":{\"statementDescription\":\"Allow client devices to perform all actions.\",\"operations\":[\"*\"],\"resources\":[\"*\"]}}}}}"
            },
            "runWith": {}
        },
        "aws.greengrass.clientdevices.IPDetector": {
            "componentVersion": "2.1.8"
        },
        "aws.greengrass.clientdevices.mqtt.Bridge": {
            "componentVersion": "2.3.1",
            "configurationUpdate": {
                "merge": "{\"reset\":[],\"merge\":{\"mqttTopicMapping\":{\"ClientDeviceTheGuate\":{\"topic\":\"clients/+/status\",\"source\":\"LocalMqtt\",\"target\":\"IotCore\"},\"ClientDeviceTheGuate2\":{\"topic\":\"clients/+/status\",\"source\":\"LocalMqtt\",\"target\":\"Pubsub\"}}}}"
            },
            "runWith": {}
        },
        "aws.greengrass.clientdevices.mqtt.Moquette": {
            "componentVersion": "2.3.5"
        },
        "aws.greengrass.labs.HomeAssistant": {
            "componentVersion": "1.0.8",
            "runWith": {}
        }
    },
    "deploymentPolicies": {
        "failureHandlingPolicy": "ROLLBACK",
        "componentUpdatePolicy": {
            "timeoutInSeconds": 60,
            "action": "NOTIFY_COMPONENTS"
        }
    },
    "iotJobConfiguration": {}
}

' > /greengrass/install/Deployment/greengrassDeploy.json.template

# Copiar el archivo greengrassDeploy.json.template
cp /greengrass/install/Deployment/greengrassDeploy.json.template /greengrass/install/Deployment/greengrassDeploy.json

# Reemplazar el valor de "targetArn" en greengrassDeploy.json
sed -i 's_"targetArn":.*_"targetArn": "'"$AWS_ARN_IOT_THING"'",_' /greengrass/install/Deployment/greengrassDeploy.json

# Ejecutar el comando de AWS CLI para crear el despliegue
aws greengrassv2 create-deployment --region=$AWS_REGION_NAME \
--cli-input-json file:///greengrass/install/Deployment/greengrassDeploy.json

# Verificar el resultado del comando anterior
if [ $? -eq 0 ]; then
    echo "Despliegue de AWS Greengrass creado satisfactoriamente."
else
    echo "Error al crear el despliegue de AWS Greengrass. Cancelando el proceso."
    exit 1
fi

echo "Proceso completado exitosamente."
echo "Brocco Hub instalado satisfactoriamente!!"
exit
