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


resource "oci_objectstorage_object" "input_folder" {
    bucket = oci_objectstorage_bucket.bucket.name
    content = ""
    namespace = data.oci_objectstorage_namespace.tenant_namespace.namespace
    object = "sdxl/input/upload_here_your_images.md"
}

resource "oci_objectstorage_object" "output_folder" {
    bucket = oci_objectstorage_bucket.bucket.name
    content = ""
    namespace = data.oci_objectstorage_namespace.tenant_namespace.namespace
    object = "sdxl/output/output_files_here.md"
}

resource "oci_logging_log_group" "log_group" {
    compartment_id = var.compartment_ocid
    display_name = "${var.instance_name}-loggroup"
}

resource "oci_logging_log" "log" {
    display_name = "${var.instance_name}-log"
    log_group_id = oci_logging_log_group.log_group.id
    log_type = "CUSTOM"
}

resource "oci_identity_dynamic_group" "dynamic_group" {
    compartment_id = var.tenancy_ocid
    description = "Dynamic group for instances in datascience project"
    matching_rule = "ANY {ALL {resource.type='datasciencenotebooksession', resource.compartment.id='${var.compartment_ocid}'}, ALL {resource.type='datasciencemodeldeployment', resource.compartment.id='${var.compartment_ocid}'}, ALL {resource.type='datasciencejobrun', resource.compartment.id='${var.compartment_ocid}'}} "
    name = "${var.instance_name}-dynamic_group"
}

resource "oci_identity_policy" "policy" {
    depends_on = [ oci_identity_dynamic_group.dynamic_group ]
    compartment_id = var.compartment_ocid
    description = "${var.instance_name}-policy"
    name = "${var.instance_name}-policy"
    statements = ["allow service datascience to manage object-family in compartment ${data.oci_identity_compartment.compartment.name} where ALL {target.bucket.name='${oci_objectstorage_bucket.bucket.name}'}",
                  "allow dynamic-group ${var.instance_name}-dynamic_group to manage data-science-family in compartment ${data.oci_identity_compartment.compartment.name}",
                  "allow dynamic-group ${var.instance_name}-dynamic_group to use log-content in compartment ${data.oci_identity_compartment.compartment.name}",
                  "allow dynamic-group ${var.instance_name}-dynamic_group to use log-groups in compartment ${data.oci_identity_compartment.compartment.name}",
                  "allow dynamic-group ${var.instance_name}-dynamic_group to manage objects in compartment ${data.oci_identity_compartment.compartment.name} where all {target.bucket.name='${oci_objectstorage_bucket.bucket.name}'}"
            ]
}

resource "oci_datascience_notebook_session" "notebook_session" {
    
    compartment_id = var.compartment_ocid
    project_id = oci_datascience_project.odsc_project.id

    display_name   = "${var.instance_name}-notebook"
    notebook_session_config_details {
        shape = var.instance_shape
        block_storage_size_in_gbs = var.compute_block_storage

        notebook_session_shape_config_details {
            memory_in_gbs = 16
            ocpus = 2
        }
    }
       
    notebook_session_runtime_config_details {
        custom_environment_variables = {"loggroup_ocid" : oci_logging_log_group.log_group.id, "log_ocid": oci_logging_log.log.id, "bucket_name":  oci_objectstorage_bucket.bucket.name}
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
