############################################
# Generate Maven settings.xml
############################################

resource "local_file" "maven_settings" {

  filename = "/var/jenkins_home/.m2/settings.xml"

  content = templatefile(
    "${path.module}/../jenkins/settings.xml.tpl",
    {
      nexus_username = var.nexus_username
      nexus_password = var.nexus_password
    }
  )

  file_permission = "0600"
}
