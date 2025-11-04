from flask import Flask, render_template, request, send_from_directory
from main import generate_terraform_script
import os
from datetime import datetime

app = Flask(__name__)

LOG_FOLDER = os.path.join(os.path.dirname(__file__), "..", "logs")
SCRIPTS_FOLDER = os.path.join(os.path.dirname(__file__), "..", "generated_scripts")

os.makedirs(LOG_FOLDER, exist_ok=True)
os.makedirs(SCRIPTS_FOLDER, exist_ok=True)

@app.route("/")
def index():
    return render_template("index.html", generated=None)

@app.route("/generate", methods=["POST"])
def generate():
    description = request.form.get("description", "")
    provider = request.form.get("provider")

    input_data = {"description": description, "provider": provider}

    if provider == "aws":
        vpc_name = request.form.get("vpc_name")
        vpc_cidr = request.form.get("vpc_cidr")
        num_subnets = int(request.form.get("num_subnets", 0))
        subnets = [
            {
                "name": request.form.get(f"subnet_name_{i}"),
                "cidr": request.form.get(f"subnet_cidr_{i}"),
                "az": request.form.get(f"subnet_az_{i}")
            } for i in range(1, num_subnets + 1)
        ]

        input_data.update({
            "vpc": {"name": vpc_name, "cidr": vpc_cidr},
            "subnets": subnets,
            "internet_gateway": request.form.get("internet_gateway") == "on",
            "route_table": request.form.get("route_table") == "on",
            "security_group": request.form.get("security_group") == "on",
            "ec2": {
                "name": request.form.get("ec2_name"),
                "type": request.form.get("ec2_type"),
                "ports": request.form.get("ec2_ports")
            }
        })

    elif provider == "azure":
        input_data.update({
            "rg": {
                "name": request.form.get("rg_name"),
                "location": request.form.get("location")
            },
            "vnet": {
                "name": request.form.get("vnet_name"),
                "cidr": request.form.get("vnet_cidr")
            },
            "subnet": {
                "name": request.form.get("subnet_name"),
                "cidr": request.form.get("subnet_cidr")
            },
            "nsg": {
                "name": request.form.get("nsg_name"),
                "ports": request.form.get("azure_ports")
            },
            "vm": {
                "name": request.form.get("vm_name"),
                "size": request.form.get("vm_size"),
                "os_type": request.form.get("os_type"),
                "admin_user": request.form.get("admin_user"),
                "admin_pass": request.form.get("admin_pass"),
                "assign_public_ip": "assign_public_ip" in request.form
            }
        })

    elif provider == "gcp":
        input_data.update({
            "project_id": request.form.get("gcp_project_id"),
            "region": request.form.get("gcp_region"),
            "vpc": {
                "name": request.form.get("gcp_vpc_name"),
                "cidr": request.form.get("gcp_vpc_cidr")
            },
            "subnet": {
                "name": request.form.get("gcp_subnet_name"),
                "cidr": request.form.get("gcp_subnet_cidr"),
                "region": request.form.get("gcp_subnet_region")
            },
            "firewall": {
                "name": request.form.get("gcp_firewall_name"),
                "ports": request.form.get("gcp_ports")
            },
            "vm": {
                "name": request.form.get("gcp_vm_name"),
                "machine_type": request.form.get("gcp_vm_type"),
                "zone": request.form.get("gcp_vm_zone"),
                "image": request.form.get("gcp_image"),
                "assign_public_ip": "gcp_assign_public_ip" in request.form
            }
        })

    terraform_code = generate_terraform_script(input_data)
    safe_desc = f"{provider}_{datetime.now().strftime('%Y%m%d_%H%M%S')}".replace(" ", "_")[:50]
    filename = f"terraform_{safe_desc}.tf"

    file_path = os.path.join(SCRIPTS_FOLDER, filename)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(terraform_code)

    return render_template("index.html", generated=True, filename=filename)

@app.route('/download/<path:filename>')
def download(filename):
    return send_from_directory(SCRIPTS_FOLDER, filename, as_attachment=True)

if __name__ == "__main__":
    app.run(debug=True)
