document.addEventListener("DOMContentLoaded", function() {
    const providerSelect = document.getElementById("provider-select");
    const awsSection = document.getElementById("aws-fields");
    const azureSection = document.getElementById("azure-fields");
    const gcpSection = document.getElementById("gcp-fields");
    const numSubnetsInput = document.getElementById("num_subnets");
    const subnetsContainer = document.getElementById("subnets_container");

    providerSelect.addEventListener("change", function() {
        awsSection.style.display = this.value === "aws" ? "block" : "none";
        azureSection.style.display = this.value === "azure" ? "block" : "none";
        gcpSection.style.display = this.value === "gcp" ? "block" : "none";
    });

    if (numSubnetsInput) {
        numSubnetsInput.addEventListener("change", function() {
            const count = parseInt(this.value);
            subnetsContainer.innerHTML = "";
            for (let i = 1; i <= count; i++) {
                subnetsContainer.innerHTML += `
                <fieldset>
                  <legend>Subnet ${i}</legend>
                  <label>Name:</label>
                  <input type="text" name="subnet_name_${i}" required />
                  <label>CIDR Range:</label>
                  <input type="text" name="subnet_cidr_${i}" required />
                  <label>Availability Zone:</label>
                  <input type="text" name="subnet_az_${i}" required />
                </fieldset>
                `;
            }
        });
    }
});
