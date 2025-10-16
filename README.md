[English Version](#provisioning-proxmox-vm-with-terraform-and-ansible) | [Versão em Português](#provisionando-vm-no-proxmox-com-terraform-e-ansible)

---
# Provisioning Proxmox VM with Terraform and Ansible
## Overview
This project automates the provisioning and configuration of a virtual machine (VM) on **Proxmox** using **Terraform** and **Ansible**.  
It clones a preconfigured **cloud-init Ubuntu template**, waits for IP assignment, and runs an **Ansible playbook** to install essential tools.

---
## Project structure
```
├── create_ci_template.sh
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── outputs.tf
├── .gitignore
├── ansible/
│   └── setup_vm.yml
└── modules/
    └── vm/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

---
## Requirements
### 1. Proxmox configuration
Create a Terraform service account with API access on Proxmox ([documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)):
```bash
# Create custom role
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

# Create user
pveum user add terraform-prov@pve --password ChooseAStrongPassword!

# Assign permissions
pveum aclmod / -user terraform-prov@pve -role TerraformProv

# Create token (note down the generated secret)
pveum user token add terraform-prov@pve tf -privsep 0
```

Example result:
```
User: terraform-prov@pve!tf
Token: 9d93c46b-f7bf-42a5-985e-db5ca9107c40
```

### 2. Cloud template creation
Create the base Ubuntu cloud-init template using [script](create_ci_template.sh).

Run on Proxmox host.
```bash
vi create_cloud_template.sh
chmod +x create_cloud_template.sh
./create_cloud_template.sh
```

---
## Requirements on local machine
- Terraform ≥ 1.6.0  
- Ansible  
- SSH key pair (`~/.ssh/id_rsa_ansible` and `~/.ssh/id_rsa_ansible.pub`)  
- SSH agent running (for keys with passphrase)

Start `ssh-agent` and load generated key:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa_ansible
ssh-add -l
```

---
## Environment variables
Export your token secret before running Terraform:

```bash
export TF_VAR_proxmox_token_secret="9d93c46b-f7bf-42a5-985e-db5ca9107c40"
```

---
## Example `terraform.tfvars` structure (must be created)
```bash
proxmox_api_url = "https://192.168.30.200:8006/api2/json"
proxmox_user    = "terraform-prov@pve!tf"
pve_node        = "hos01"
```

---
## Deployment steps
```bash
terraform init
terraform plan
terraform apply
```

Terraform will:
1. Clone the `ubuntu-2404-ci` template on the specified node.  
2. Wait for IP assignment (via QEMU guest agent).  
3. Create a temporary Ansible inventory.  
4. Run the Ansible playbook (`ansible/setup_vm.yml`) to:
   - Test SSH connection  
   - Update and upgrade packages  
   - Install base utilities (`vim`, `htop`, `tcpdump`, `nmap`, `telnet`)

---
## Outputs
After completion, Terraform prints:
| Output | Description |
|--------|--------------|
| `vm_name` | Name of the created VM |
| `vm_ip_address` | IP address assigned by DHCP |

---
## Notes
- `cloud-init` **must not** use `admin` as the username (causes SSH permission issues).  
- The Ansible inventory file is created temporarily and removed automatically.  
- Sensitive data such as `.tfvars` and tokens are excluded via `.gitignore`.

---
# Provisionando VM no Proxmox com Terraform e Ansible
## Visão Geral
Este projeto automatiza a **criação e configuração de uma máquina virtual no Proxmox** usando **Terraform e Ansible**.  
Ele clona um **template Ubuntu com cloud-init**, aguarda o IP ser atribuído e executa um **playbook Ansible** para instalar pacotes essenciais.

---
## Estrutura do Projeto
```
├── create_ci_template.sh
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── outputs.tf
├── .gitignore
├── ansible/
│   └── setup_vm.yml
└── modules/
    └── vm/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

---
## Requisitos
### 1. Configuração no Proxmox
Crie um usuário e token para o Terraform ([documentação](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)):
```bash
# Criar uma role personalizada
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

# Criar usuário
pveum user add terraform-prov@pve --password ChooseAStrongPassword!

# Atribuir permissões
pveum aclmod / -user terraform-prov@pve -role TerraformProv

# Criar token (anote o token gerado)
pveum user token add terraform-prov@pve tf -privsep 0
```

Exemplo de saída:
```
User: terraform-prov@pve!tf
Token: 9d93c46b-f7bf-42a5-985e-db5ca9107c40
```

### 2. Criação do template cloud-init
Execute o [script](create_ci_template.sh).

Executar no hospedeiro Proxmox:
```bash
vi create_cloud_template.sh
chmod +x create_cloud_template.sh
./create_cloud_template.sh
```

---
## Requisitos locais
- Terraform ≥ 1.6.0  
- Ansible  
- Par de chaves SSH (`~/.ssh/id_rsa_ansible` e `~/.ssh/id_rsa_ansible.pub`)  
- SSH Agent ativo (para chaves com passphrase)

Inicie o `ssh-agent` e adicione a chave gerada:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa_ansible
ssh-add -l
```

---
## Variáveis de ambiente
Antes de executar o Terraform:

```bash
export TF_VAR_proxmox_token_secret="9d93c46b-f7bf-42a5-985e-db5ca9107c40"
```

---
## Exemplo de estrutura do `terraform.tfvars` (deve ser criado)
```bash
proxmox_api_url = "https://192.168.30.200:8006/api2/json"
proxmox_user    = "terraform-prov@pve!tf"
pve_node        = "hos01"
```

---
## Execução
```bash
terraform init
terraform plan
terraform apply
```

O Terraform irá:
1. Clonar o template `ubuntu-2404-ci` no hospedeiro especificado.  
2. Aguardar o IP ser atribuído via QEMU Guest Agent.  
3. Criar um inventário temporário para o Ansible.  
4. Executar o playbook (`ansible/setup_vm.yml`) que:
   - Testa a conexão SSH  
   - Atualiza os pacotes  
   - Instala ferramentas básicas (`vim`, `htop`, `tcpdump`, `nmap`, `telnet`)

---
## Saídas
Após o término, serão exibidos:
| Saída | Descrição |
|--------|------------|
| `vm_name` | Nome da VM criada |
| `vm_ip_address` | Endereço IP atribuído |

---
## Observações
- O usuário `admin` não deve ser usado no Cloud-Init (problemas de SSH).  
- O inventário é criado e removido automaticamente.  
- Arquivos sensíveis (`*.tfvars`, tokens) são ignorados pelo `.gitignore`.