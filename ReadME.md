Step 1: Terraform (The Infrastructure)

Your Terraform code acts as the "provisioner." It talks to Scaleway (or your chosen provider) to request resources.

    Define the Provider: Create a main.tf file. Set up the Scaleway provider with your Project ID and Region.

    Create a Security Group: Define rules to allow traffic on ports 80 (HTTP), 443 (HTTPS), and 22 (SSH). Ensure all other ports (especially your Database port) are blocked from the public internet.

    Provision the Instance: Use the scaleway_instance_server resource.

        Image: Set this to ubuntu_focal (Ubuntu 20.04).

        Type: Use a small instance like DEV1-S to save credits.

    Attach an IP: Use scaleway_instance_ip so your server has a static public address.

    Output the IP: Create an outputs.tf file that prints the server's public IP. You will need this for Ansible.

Step 2: Handoff (The Bridge)

Ansible needs to know which IP address to connect to.

    Run Terraform: Execute terraform apply.

    Create an Inventory: Create a file named inventory.ini. Manually (or via a script) add the IP address from the Terraform output:
    Ini, TOML

    [webserver]
    XXX.XXX.XXX.XXX ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

Step 3: Ansible (The Configuration)

Create a playbook.yml that transforms the blank Ubuntu server into a Docker host.

    Install System Dependencies: Add tasks to install apt-transport-https, ca-certificates, curl, and python3-pip.

    Install Docker: Add the Docker GPG key, repository, and install the docker-ce and docker-compose-plugin packages.

    Prepare Directories: Create the necessary directories on the remote server (e.g., /home/root/inception/data) where your WordPress and Database volumes will live.

    Transfer Files: Use the copy or synchronize module to move your local Inception folder (containing your docker-compose.yml, Nginx configs, and Dockerfiles) to the server.

    Environment Variables: Use the template module to copy a .env.j2 file to the server. This ensures your secrets (DB passwords) are injected into the environment.

Step 4: Deployment (The "Inception" Launch)

The final tasks in your Ansible playbook actually start the site.

    Docker Login (Optional): If you use a private registry, log in now.

    Run Compose: Use the Ansible community.docker.docker_compose module to run your project.

        Set project_src to the folder you transferred.

        Set state to present.

        Set build: yes to ensure the images are built on the remote server as per the project requirements.

Step 5: Verification

    Check Persistence: Manually reboot the server via the cloud console. Wait a minute and check if your WordPress site comes back up automatically (ensure your Docker containers have restart: always or restart: unless-stopped in the docker-compose.yml).

    Check Security: Try to connect to your Database port from your local machine. It should be blocked.

    Check TLS: Visit your site via https:// to ensure your Nginx container is correctly serving the SSL certificates.

Summary Checklist for your Submission

    [ ] terraform/ directory with .tf files.

    [ ] ansible/ directory with playbook.yml and inventory.ini.

    [ ] Your existing docker-compose.yml and Dockerfiles.

    [ ] A Makefile or deploy.sh script that runs both tools in order.
