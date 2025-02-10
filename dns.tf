# data "aws_route53_zone" "selected" {
#   name = "nbaplaydb.com"
# }

# resource "aws_route53_record" "elastic" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = "elastic.${data.aws_route53_zone.selected.name}"
#   type    = "A"
#   ttl     = "300"
#   records = [aws_eip.elastic_ip.public_ip]
# }