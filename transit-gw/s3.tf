resource "aws_s3_bucket" "lab_data" {
  bucket = "lab-data.local-domain.not-domain"
  acl    = "private"

  tags = {
    Name = "Lab Data"
  }
}
