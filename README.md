# 🚀 Azure Policy – Etiquetas obligatorias

> **Objetivo:** Denegar la creación de recursos en Azure que no tengan las etiquetas requeridas por FinOps/SecOps, usando **Terraform** y **Azure Policy**.

---

## 📚 Índice

- [📐 Arquitectura lógica](#-arquitectura-lógica)
- [⚙️ Requisitos previos](#-requisitos-previos)
- [🗂️ Estructura del proyecto](#-estructura-del-proyecto)
- [📄 Descripción de archivos .tf](#-descripción-de-archivos-tf)
- [💰 Coste estimado](#-coste-estimado)
- [🚦 Despliegue paso a paso](#-despliegue-paso-a-paso)
- [✅ Verificación](#-verificación)
- [⚠️ Excepción para Resource Groups](#️-excepción-para-resource-groups)
- [🧹 Limpieza](#-limpieza)
- [❓ Preguntas frecuentes](#-preguntas-frecuentes)
- [🔗 Referencias](#-referencias)

---

## 📐 Arquitectura lógica

```text
┌──────────────────────────────────────────────────────┐
│                  Suscripción Azure                   │
│ (/subscriptions/<GUID>)                              │
│                                                      │
│ ◉ Policy Definition: require-tags-<rand>             │
│   - Deny si faltan: environment, cost_center, owner  │
│                                                      │
│ ◉ Policy Assignment: enforce-required-tags           │
│   - Scope: Suscripción completa                      │
│   - Effect: Deny                                     │
└──────────────────────────────────────────────────────┘
```

🛠️ Recursos creados por Terraform: **2**  
💸 Coste de Azure Policy: **$0**

---

## ⚙️ Requisitos previos

| Herramienta    | Versión mínima | Instalado en       |
|----------------|----------------|--------------------|
| Terraform      | 1.7            | WSL Ubuntu 24.04   |
| Azure CLI      | 2.60           | WSL                |
| Cuenta Azure   | Contributor    | Subscripción activa|

---

## 🗂️ Estructura del proyecto

```
policy-required-tags/
├── policy-tags.tf     # Definición y asignación de la política
├── variables.tf       # Lista de etiquetas requeridas
└── outputs.tf         # IDs resultantes (útiles para auditoría)
```

---

## 📄 Descripción de archivos .tf

| Archivo        | Contenido clave                                                                 | Comentarios                          |
|----------------|----------------------------------------------------------------------------------|--------------------------------------|
| `policy-tags.tf` | Provider + data source + definición y asignación con efecto Deny               | Tarda ~2 min por la latencia de Azure|
| `variables.tf`   | Lista `required_tags`: `environment`, `cost_center`, `owner`                  | Puedes añadir más etiquetas          |
| `outputs.tf`     | Muestra los IDs de la definición y asignación                                 | Útil para debugging o auditorías     |

---

## 💰 Coste estimado

| Recurso            | Precio | Comentario                             |
|--------------------|--------|----------------------------------------|
| Policy Definition  | $0     | Metadatos                              |
| Policy Assignment  | $0     | Evaluación gratuita de Azure Policy    |

---

## 🚦 Despliegue paso a paso

```bash
# 1. Login y selecciona tu suscripción
az login --use-device-code
az account show --query id -o tsv

# 2. Init & Apply
terraform init -upgrade
terraform apply -auto-approve
```

🕒 Espera **~2–4 min** hasta que Terraform indique que todo está creado.

---

## ✅ Verificación

```bash
# Esto DEBE fallar:
az group create -l eastus2 -n rg-notags || echo "💥 Bloqueado por política"

# Esto DEBE pasar:
az group create -l eastus2 -n rg-ok \
  --tags environment=lab cost_center=demo owner=tu@correo.com
```

⏳ Espera **~60s** tras el `terraform apply` antes de validar — Azure necesita propagar la política.

---

## ⚠️ Excepción para Resource Groups

Actualmente se excluyen los RG con esta regla:

```json
{ "field": "type", "notEquals": "Microsoft.Resources/subscriptions/resourceGroups" }
```

📝 Esto permite crear RG sin tags, pero los recursos dentro sí deben tenerlas.

### ➖ ¿Cómo eliminar esta excepción?

1. Edita `policy-tags.tf` y **elimina** la línea anterior del bloque de condiciones.
2. Ejecuta:

```bash
terraform apply -auto-approve
```

3. Ahora `az group create` sin tags será denegado. 💥

---

## 🧹 Limpieza

```bash
# Borra política y asignación
terraform destroy -auto-approve

# Borra RGs de prueba
az group delete -n rg-notags --yes --no-wait || true
az group delete -n rg-ok     --yes --no-wait || true
```

---

## ❓ Preguntas frecuentes

| Pregunta                                             | Respuesta breve                                                   |
|------------------------------------------------------|-------------------------------------------------------------------|
| ¿Genera costo la política?                          | No. Solo pagas si activas Defender for Cloud (versión paga).     |
| ¿Puedo asignarla a un RG en lugar de la suscripción?| Sí, usando `scope = ".../resourceGroups/<rg>"`                    |
| ¿Puedo exigir valores específicos en los tags?       | Sí. Ejemplo: `{ field: "tags.environment", equals: "prod" }`     |

---

## 🔗 Referencias

- [📘 Azure Policy Overview](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
- [📗 Terraform azurerm_policy_definition](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition)
- [🏷️ FinOps Foundation – Govern Tagging](https://www.finops.org/framework/capabilities/govern-tagging/)

---

⌛ **Duración estimada:**  
5 min (setup) + 4 min (deploy) + 1 min (verificación) = **¡10 minutos y listo!** 🎯
