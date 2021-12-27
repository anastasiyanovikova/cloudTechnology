terraform {
  required_version = ">=1.0.0"
  required_providers {
    rustack={
      source = "pilat/rustack"
      version = "0.1.9"
    }
  }
}

provider "rustack" {
  api_endpoint = "https://cloud.mephi.ru"
  token = "токен"

}

# Получение параметров созданного автоматически проекта по его имени (шаг 2)
data "rustack_project" "my_project" {
    name = "Мой проект"
}

# Получение параметров доступного гипервизора KVM по его имени и по id проекта (шаг 3)
data "rustack_hypervisor" "kvm" {
    project_id = data.rustack_project.my_project.id
    name = "KVM"
}

# Создание ВЦОД KVM.
# Задаём его имя, указываем id проекта, который получили на шаге 2 при обращении к datasource rustack_project
# Указываем id гипервизора, который получили на шаге 3 при обращении к datasource rustack_hypervisor (шаг 4)
resource "rustack_vdc" "vdc1" {
    name = "KVM Terraform 2"
    project_id = data.rustack_project.my_project.id
    hypervisor_id = data.rustack_hypervisor.kvm.id
}

# Получение параметров автоматически созданной при создании ВЦОД сервисной сети по её имени и id созданного ВЦОД, который получили на шаге 4 при создании resource rustack_vdc (шаг 5)
data "rustack_network" "service_network" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Сеть"
}

# Получение параметров доступного типа дисков по его имени и id созданного ВЦОД, который получили на шаге 4 при создании resource rustack_vdc (шаг 6)
data "rustack_storage_profile" "ocfs2" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "ocfs2"
}

# Получение параметров доступного шаблона ОС по его имени и id созданного ВЦОД, который получили на шаге 4 при создании resource rustack_vdc (шаг 7)
data "rustack_template" "docker20" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Docker 20.10 (Ubuntu 20.04)"
}

# Получение параметров доступного шаблона брандмауера по его имени и id созданного ВЦОД, который получили на шаге 4 при создании resource rustack_vdc (шаг 8)
data "rustack_firewall_template" "allow_default" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "По-умолчанию"
}

data "rustack_firewall_template" "allow_web" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Разрешить WEB"
}

data "rustack_firewall_template" "allow_ssh" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Разрешить SSH"
}

data "rustack_firewall_template" "allow_all_ingress" {
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Разрешить входящий трафик"
}



resource "time_sleep" "wait_30_seconds" {
  depends_on = [rustack_vdc.vdc1]
  create_duration = "30s"
}

# Создание сервера.
# Задаём его имя и конфигурацию. Выбираем шаблон ОС по его id, который получили на шаге 7. Ссылаемся на скрипт инициализации. Указываем размер и тип основного диска.
# Выбираем Сеть в которую будет подключен сервер по её id, который получили на шаге 5.
# Выбираем шаблон брандмауера по его id, который получили на шаге 8. Указываем, что необходимо получить публичный адрес.
resource "rustack_vm" "vm" {

    depends_on = [time_sleep.wait_30_seconds]
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Server 1"
    cpu = 2
    ram = 2

    template_id = data.rustack_template.docker20.id

    user_data = "${file("user_data.yaml")}"

    system_disk = "20-ocfs2"

    port {
        network_id = data.rustack_network.service_network.id
        firewall_templates = [
            data.rustack_firewall_template.allow_default.id,
          data.rustack_firewall_template.allow_ssh.id,
          data.rustack_firewall_template.allow_web.id,
          data.rustack_firewall_template.allow_all_ingress.id
        ]
    }

    floating = true
}

resource "rustack_vm" "vm2" {

    depends_on = [time_sleep.wait_30_seconds]
    vdc_id = resource.rustack_vdc.vdc1.id
    name = "Server 2"
    cpu = 2
    ram = 2

    template_id = data.rustack_template.docker20.id

    user_data = "${file("user_data.yaml")}"

    system_disk = "20-ocfs2"

    port {
        network_id = data.rustack_network.service_network.id
        firewall_templates = [
            data.rustack_firewall_template.allow_default.id,
          data.rustack_firewall_template.allow_ssh.id,
          data.rustack_firewall_template.allow_web.id,
          data.rustack_firewall_template.allow_all_ingress.id
        ]
    }

    floating = true
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [rustack_vm.vm]
  create_duration = "60s"
}

resource "local_file" "urllogic" {
    content     = "${rustack_vm.vm.floating_ip}"
    filename = "/opt/urllogic.txt"
}

resource "null_resource" "next" {
  depends_on = [time_sleep.wait_60_seconds]
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /opt",
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }
    provisioner "file" {
    source = "/opt/logic/run.sh"
    destination = "/opt/run.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }

    provisioner "file" {
    source = "/opt/logic/main.py"
    destination = "/opt/main.py"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }

  provisioner "file" {
    source = "/opt/logic/wsgi.py"
    destination = "/opt/wsgi.py"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }

  provisioner "file" {
    source = "/opt/logic/requirements.txt"
    destination = "/opt/requirements.txt"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }

  provisioner "file" {
    source = "/opt/logic/Dockerfile"
    destination = "/opt/Dockerfile"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt",
      "sudo docker build . --tag logicserver",
      "sudo docker run -d -p 5000:5000 --restart=always logicserver",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm.floating_ip}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /opt",
      "sudo mkdir /opt/templates",
      "sudo chmod 777 /opt/templates",
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }
    provisioner "file" {
    source = "/opt/web/run.sh"
    destination = "/opt/run.sh"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

    provisioner "file" {
    source = "/opt/urllogic.txt"
    destination = "/opt/urllogic.txt"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }
    provisioner "file" {
    source = "/opt/web/main.py"
    destination = "/opt/main.py"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

  provisioner "file" {
    source = "/opt/web/wsgi.py"
    destination = "/opt/wsgi.py"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

  provisioner "file" {
    source = "/opt/web/requirements.txt"
    destination = "/opt/requirements.txt"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

  provisioner "file" {
    source = "/opt/web/Dockerfile"
    destination = "/opt/Dockerfile"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

    provisioner "file" {
    source = "/opt/web/templates/showVacancyByName.html"
    destination = "/opt/templates/showVacancyByName.html"

    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt",
      "sudo docker build . --tag webinterface",
      "sudo docker run -d -p 5000:5000 --restart=always webinterface",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      password = "Ubuntu1111"
      host = "${rustack_vm.vm2.floating_ip}"
    }
  }

}
