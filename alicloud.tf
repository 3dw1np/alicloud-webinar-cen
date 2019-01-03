provider "alicloud" {
  region     = "eu-central-1"
}

provider "alicloud" {
  alias      = "china"
  region     = "cn-hangzhou"
}

data "alicloud_zones" "zones_europe" {
  available_instance_type = "ecs.xn4.small"
  available_disk_category = "cloud_ssd"
}

data "alicloud_zones" "zones_china" {
  provider                = "alicloud.china"
  available_instance_type = "ecs.xn4.small"
  available_disk_category = "cloud_ssd"
}

resource "alicloud_vpc" "vpc_europe" {
  name        = "vpc_cen_europe"
  cidr_block  = "10.100.0.0/16"
}

resource "alicloud_vpc" "vpc_china" {
  provider    = "alicloud.china"
  name        = "vpc_cen_china"
  cidr_block  = "10.200.0.0/16"
}

resource "alicloud_vswitch" "vswitch_europe" {
  name              = "vswitch_cen_europe"
  vpc_id            = "${alicloud_vpc.vpc_europe.id}"
  cidr_block        = "10.100.0.0/24"
  availability_zone = "${data.alicloud_zones.zones_europe.zones.0.id}"
}

resource "alicloud_vswitch" "vswitch_china" {
  provider          = "alicloud.china"
  name              = "vswitch_cen_china"
  vpc_id            = "${alicloud_vpc.vpc_china.id}"
  cidr_block        = "10.200.0.0/24"
  availability_zone = "${data.alicloud_zones.zones_china.zones.0.id}"
}

####

resource "alicloud_cen_instance" "cen" {
  name = "cen_webinar"
}

resource "alicloud_cen_instance_attachment" "vpc_europe_attach" {
  instance_id              = "${alicloud_cen_instance.cen.id}"
  child_instance_id        = "${alicloud_vpc.vpc_europe.id}"
  child_instance_region_id = "eu-central-1"
}

resource "alicloud_cen_instance_attachment" "vpc_china_attach" {
  instance_id              = "${alicloud_cen_instance.cen.id}"
  child_instance_id        = "${alicloud_vpc.vpc_china.id}"
  child_instance_region_id = "cn-hangzhou"
}

# resource "alicloud_cen_bandwidth_package" "bwp" {
#   bandwidth             = "2"
#   period                = 1
#   charge_type           = "PrePaid"
#   geographic_region_ids = ["China", "Europe"]
# }

# resource "alicloud_cen_bandwidth_package_attachment" "bwp_attach" {
#   instance_id          = "${alicloud_cen_instance.cen.id}"
#   bandwidth_package_id = "${alicloud_cen_bandwidth_package.bwp.id}"
# }

# resource "alicloud_cen_bandwidth_limit" "bwp_limit" {
#   instance_id     = "${alicloud_cen_instance.cen.id}"
#   region_ids      = ["eu-central-1", "cn-hangzhou"]
#   bandwidth_limit = "2"
#   depends_on      = [
#     "alicloud_cen_bandwidth_package_attachment.bwp_attach",
#     "alicloud_cen_instance_attachment.vpc_europe_attach",
#     "alicloud_cen_instance_attachment.vpc_china_attach"]
# }


###

resource "alicloud_security_group" "sg_europe" {
  name   = "webinar_ssh_sg"
  vpc_id = "${alicloud_vpc.vpc_europe.id}"
}

resource "alicloud_security_group_rule" "allow_ssh_access_europe" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_europe.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_icmp_traffic_europe" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_europe.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_instance" "instance_europe" {
  instance_name              = "webinar_europe_srv"
  instance_type              = "ecs.xn4.small"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 40
  image_id                   = "ubuntu_18_04_64_20G_alibase_20181212.vhd"

  vswitch_id                 = "${alicloud_vswitch.vswitch_europe.id}"
  internet_max_bandwidth_out = 1

  security_groups            = ["${alicloud_security_group.sg_europe.id}"]
  password                   = "789636Az&"
}


#####

resource "alicloud_security_group" "sg_china" {
  provider = "alicloud.china"
  name     = "webinar_ssh_sg"
  vpc_id   = "${alicloud_vpc.vpc_china.id}"
}

resource "alicloud_security_group_rule" "allow_ssh_access_china" {
  provider          = "alicloud.china"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_china.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_icmp_traffic_china" {
  provider          = "alicloud.china"
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_china.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_instance" "instance_china" {
  provider                   = "alicloud.china"
  instance_name              = "webinar_china_srv"
  instance_type              = "ecs.xn4.small"
  system_disk_category       = "cloud_ssd"
  system_disk_size           = 40
  image_id                   = "ubuntu_18_04_64_20G_alibase_20181212.vhd"

  vswitch_id                 = "${alicloud_vswitch.vswitch_china.id}"
  internet_max_bandwidth_out = 0 // Only private IP

  security_groups            = ["${alicloud_security_group.sg_china.id}"]
  password                   = "789636Az&"
}


output "instance_public_ip_europe" {
  value = "${alicloud_instance.instance_europe.public_ip}"
}

output "instance_private_ip_china" {
  value = "${alicloud_instance.instance_china.private_ip}"
}


















