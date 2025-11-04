import os
import json
from dotenv import load_dotenv
import google.generativeai as genai

# Load API key from .env file
load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    raise ValueError("GEMINI_API_KEY not set in .env")

# Configure Gemini
genai.configure(api_key=API_KEY)

def generate_terraform_script(input_data):
    """
    Sends structured infrastructure request including description to Gemini and returns Terraform code.
    input_data: dict with keys like 'description', 'provider', and cloud-specific resources.
    """

    provider = input_data.get("provider", "AWS").upper()
    description = input_data.get("description", "")

    # Prepare prompt JSON for better readability in the LLM
    structured_data = input_data.copy()
    structured_data.pop("description", None)  # Remove description, which will be handled separately

    prompt = f"""
You are an expert DevOps infrastructure engineer.

Here is a detailed description of the infrastructure request:

{description}

Cloud Provider: {provider}

Additional structured requirements (as JSON):
{json.dumps(structured_data, indent=2)}

Generate a complete, valid Terraform script for this infrastructure using best practices.
OUTPUT ONLY valid Terraform code in HCL format. DO NOT include explanations or any extraneous text.
"""

    model = genai.GenerativeModel("gemini-2.5-flash")
    response = model.generate_content(prompt)

    terraform_code = response.text.strip()

    if not terraform_code:
        terraform_code = f"# Failed to generate Terraform code for input: {description}"

    return terraform_code
