provider "aws" {
  region = var.region
}

# first model
resource "aws_sagemaker_model" "m1" {
  name = var.model_name_1
  execution_role_arn = var.model_arn_1

  primary_container {
    image = var.docker_image_1
    model_data_url = var.model_location_1
  }
}

# second model
resource "aws_sagemaker_model" "m2" {
  name = var.model_name_2
  execution_role_arn = var.model_arn_2

  primary_container {
    image = var.docker_image_2
    model_data_url = var.model_location_2
  }
}

# endpoint configuration for both models
resource "aws_sagemaker_endpoint_configuration" "ec" {
  name = var.endpoint_config_name

  production_variants {
    variant_name           = "variant-1"
    model_name             =  var.model_name_1
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
    initial_variant_weight = 1
  }

  production_variants {
    variant_name           = "variant-2"
    model_name             =  var.model_name_2
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
    initial_variant_weight = 0
  }

  depends_on = [aws_sagemaker_model.m1]
}

resource "aws_sagemaker_endpoint" "e" {
  name                 = var.endpoint_name
  endpoint_config_name = var.endpoint_config_name
  
  depends_on = [aws_sagemaker_endpoint_configuration.ec]
}
