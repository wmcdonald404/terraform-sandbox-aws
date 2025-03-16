# Sample .tfvars. This represents moderately sensitive
# data that would not typically be versioned directly.
# It could be sourced from SSM parameters, Github Actions
# Secrets/Variables or similar 

keypair            = "wmcdonald@gmail.com aws ed25519-key-20211205"
base_instance_type = "t3.small"
ami                = "debian12" 