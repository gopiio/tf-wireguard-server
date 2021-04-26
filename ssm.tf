# Create encrypted parameter in AWS SSM Parameter Store
resource "aws_ssm_parameter" "this" {
  name = format("%s%s", var.ssm_secret_prefix, local.name)
  type = "SecureString"

  # TODO: replace with wireguard_config_document datasource of OJFord/wireguard provider:
  # ref.https://registry.terraform.io/providers/OJFord/wireguard/latest/docs/data-sources/config_document
  value = templatefile(
    "${path.module}/templates/wg0.conf.tmpl",
    {
      name        = var.name_prefix
      address     = var.wg_cidr
      listen_port = var.wg_listen_port
      routes      = var.wg_routes
      private_key = var.wg_private_key
      dns_server  = var.dns_server
      peers       = var.wg_peers
    }
  )
}
