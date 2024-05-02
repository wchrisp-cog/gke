output "your_external_ip" {
  description = "Your external IP address."
  value       = data.http.ip.response_body
}