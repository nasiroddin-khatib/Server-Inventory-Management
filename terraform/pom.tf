############################################
# Generate backend pom.xml
############################################

resource "local_file" "backend_pom" {

  filename = "${path.module}/../backend/pom.xml"

  content = templatefile(
    "${path.module}/../backend/pom.xml.tpl",
    {
      nexus_ip = aws_instance.nexus.public_ip
    }
  )
}
