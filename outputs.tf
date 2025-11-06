output "public-ip-address" {
 # value = aws_instance.My_EC2.public_ip
 value = { for instance, value in aws_instance.My_EC2 :
   instance => {
       name = value.tags["name"]
       public_ip_details = value.public_ip
   }
 }
}

#output "instance_ips" {
  #value = [for inst in aws_instance.My_EC2 : inst.public_ip]
#}
