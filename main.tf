terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "terra_network" {
  name = "terra_network"
}

resource "docker_image" "pxc0" {
  name = "zhy7ne/pxc_node0:3.0"
  keep_locally = false
}

resource "docker_image" "pxc1" {
  name = "percona/percona-xtradb-cluster:5.7"
  keep_locally = false
}

resource "docker_container" "pxc_node0" {
  image = "zhy7ne/pxc_node0:3.0"
  name = "pxc_node0"
  env = [
    "MYSQL_ALLOW_EMPTY_PASSWORD=yes",
    "MYSQL_ROOT_PASSWORD=password",
    "MYSQL_INITDB_SKIP_TZINFO=yes",
    "XTRABACKUP_PASSWORD=password",
    "PXC_ENCRYPT_CLUSTER_TRAFFIC=0",
  ]
  ports {
    internal = 3306
    external = 33060
  }
  network_mode = docker_network.terra_network.name
}

resource "docker_container" "pxc_node1" {
  count = 2
  image = "percona/percona-xtradb-cluster:5.7"
  name = "pxc_node${count.index + 1}"
  env = [
    "MYSQL_ALLOW_EMPTY_PASSWORD=yes",
    "MYSQL_ROOT_PASSWORD=password",
    "MYSQL_INITDB_SKIP_TZINFO=yes",
    "XTRABACKUP_PASSWORD=password",
    "CLUSTER_NAME=terracluster",
    "CLUSTER_JOIN=pxc_node0",
    "name=pxc_node${count.index + 1}",
    "net=terra_network",
    "PXC_ENCRYPT_CLUSTER_TRAFFIC=0",
  ]
  ports {
    internal = 3306
    external = 33061 + count.index
  }
  network_mode = docker_network.terra_network.name
}
