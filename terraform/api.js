############################################
# Generate Dynamic frontend/api.js
############################################

resource "local_file" "frontend_api_js" {

  filename = "${path.module}/../frontend/api.js"

  content = templatefile(
    "${path.module}/../frontend/api.js.tpl",
    {
      alb_dns_name = aws_lb.backend.dns_name
    }
  )

}
