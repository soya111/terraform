# Terraform

terraform graph > graph.dot

dot -Tpng graph.dot -o graph.png

terraform apply -replace="aws_instance.nginx"
