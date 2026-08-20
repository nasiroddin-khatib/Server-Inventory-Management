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


############################################
# Upload Static Frontend Files to S3
############################################

resource "aws_s3_object" "frontend_files" {

  for_each = {
    for file in fileset("${path.module}/../frontend", "**") :
    file => file
    if file != "api.js.tpl" && file != "api.js"
  }

  bucket = aws_s3_bucket.frontend.id

  key = each.value

  source = "${path.module}/../frontend/${each.value}"

  etag = filemd5("${path.module}/../frontend/${each.value}")
}


############################################
# Upload Generated Dynamic api.js to S3
############################################

resource "aws_s3_object" "frontend_api_js" {

  bucket = aws_s3_bucket.frontend.id

  key = "api.js"

  source = local_file.frontend_api_js.filename

  content_type = "application/javascript"

  etag = filemd5(local_file.frontend_api_js.filename)

  depends_on = [
    local_file.frontend_api_js
  ]
}
