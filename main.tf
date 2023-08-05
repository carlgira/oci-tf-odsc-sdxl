data "oci_objectstorage_namespace" "tenant_namespace" {
    compartment_id = var.compartment_id
}

resource "oci_objectstorage_bucket" "bucket" {
    compartment_id = var.compartment_id
    name = "${var.instance_name}-bucket"
    namespace = oci_objectstorage_namespace.tenant_namespace.namespace
}

resource "oci_identity_policy" "policy" {
    compartment_id = var.compartment_id
    description = "${var.instance_name}-policy"
    name = "${var.instance_name}-policy"
    statements = "Allow service datascience to manage object-family in compartment ${var.compartment_id} where ALL {target.bucket.name='${oci_objectstorage_bucket.bucket.name}'}"
}

resource "oci_datascience_notebook_session" "notebook_session" {
    
    compartment_id = var.compartment_id
    project_id = oci_datascience_project.odsc_project.id

    display_name   = "${var.instance_name}-notebook"
    notebook_session_config_details {
        shape = var.instance_name
        block_storage_size_in_gbs = var.compute_block_storage
        subnet_id = oci_core_subnet.subnet.id
    }
    
    notebook_session_runtime_config_details {
        notebook_session_git_config_details {
            notebook_session_git_repo_config_collection {
                url = var.github_repo
            }
        }
    }
}

resource "oci_datascience_project" "odsc_project" {
    compartment_id = var.compartment_id
    display_name   = "${var.instance_name}-odcs-project"
}

# Create internet gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.infra_vcn.id
  display_name   = "${var.instance_name}-internet-gateway"
}

# Create route table
resource "oci_core_route_table" "infra_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.infra_vcn.id
  display_name   = "${var.instance_name}-route-table"
  route_rules {
    destination = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# Create security list with ingress and egress rules
resource "oci_core_security_list" "infra_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.infra_vcn.id
  display_name   = "${var.instance_name}-security-list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all outbound traffic"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = "0.0.0.0/0"
    description = "Allow all inbound traffic"
  }

  # ingress rule for ssh
    ingress_security_rules {
        protocol    = "6" # tcp
        source      = "0.0.0.0/0"
        description = "Allow ssh"
        tcp_options {
            max = 22
            min = 22
        }
    }
}

# Create a subnet
resource "oci_core_subnet" "subnet" {
  cidr_block        = var.subnet_cidr
  compartment_id    = var.compartment_ocid
  display_name      = "${var.instance_name}-subnet"
  vcn_id            = oci_core_virtual_network.infra_vcn.id
  route_table_id    = oci_core_route_table.infra_route_table.id
  security_list_ids = ["${oci_core_security_list.infra_security_list.id}"]
  dhcp_options_id   = oci_core_virtual_network.infra_vcn.default_dhcp_options_id
}

# Create a virtual network
resource "oci_core_virtual_network" "infra_vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_name}-vcn"
}