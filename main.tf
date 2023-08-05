data "oci_objectstorage_namespace" "tenant_namespace" {
    compartment_id = var.compartment_ocid
}

data "oci_identity_compartment" "compartment" {
    id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "bucket" {
    compartment_id = var.compartment_ocid
    name = "${var.instance_name}-bucket"
    namespace = data.oci_objectstorage_namespace.tenant_namespace.namespace
}

resource "oci_identity_policy" "policy" {
    compartment_id = var.compartment_ocid
    description = "${var.instance_name}-policy"
    name = "${var.instance_name}-policy"
    statements = ["Allow service datascience to manage object-family in compartment ${data.oci_identity_compartment.compartment.name} where ALL {target.bucket.name='${oci_objectstorage_bucket.bucket.name}'}"]
}

resource "oci_datascience_notebook_session" "notebook_session" {
    
    compartment_id = var.compartment_ocid
    project_id = oci_datascience_project.odsc_project.id

    display_name   = "${var.instance_name}-notebook"
    notebook_session_config_details {
        shape = var.instance_shape
        block_storage_size_in_gbs = var.compute_block_storage
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
    compartment_id = var.compartment_ocid
    display_name   = "${var.instance_name}-odcs-project"
}
