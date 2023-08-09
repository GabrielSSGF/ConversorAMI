<h1 align="center">
  <br>
  <a href="https://www.atlassian.com/software/jira"><img src="https://d1.awsstatic.com/PTNR_AWS_logo_300x300_BWColor.8a63bc4699377744833f0da71b08acc09bc1b85c.png" alt="Jira" width="200"></a>
  <br>
  VMDK/VMX Converter to AMI
  <br>
</h1>

<h4 align="center">A virtual machine converter for AWS implementations.</h4>

This documentation aims to explain the operation and use of the Linux shell script that automates the processes of converting and importing VMX/VMDK files to AWS as an AMI.

# Operation

1. The script will check for a **.7z** file inside a folder called `$CONVERT_FOLDER` ;
2. When finding the **.7z** file, it will be converted and sent to a folder called `$EXTRACT_FOLDER`;
3. After unpacking the file, the script will look for the **.vmx** file, use **OVFTool** to convert the file to **.ova** format, and then move it to a folder called `$EXPORT_FOLDER`;
4. With the conversion finished, the **.ova** file will be uploaded to the **S3** bucket `$BUCKET_NAME`;
6. And finally, after uploading to **S3**, the **.ova** file will be imported as **AMI** with the **SAME NAME** as the **.7z** file;
7. At the end of the process, **ALL** files placed in the `$CONVERT_FOLDER` folder will be deleted.
> It is `EXTREMELY` important to make it clear that the script will only work correctly by placing **ONLY ONE** **.7z** file at a time in the `$CONVERT_FOLDER`

## Requirements
- AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- OVFTool: https://customerconnect.vmware.com/downloads/get-download?downloadGroup=OVFTOOL441
- p7zip: https://www.7-zip.org/download.html
