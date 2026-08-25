# OTMS application images

This directory implements the artifact-promotion stage of the OTMS delivery flow.
Packer never clones or recompiles an application. Jenkins supplies the package,
checksum and `artifact-manifest.json` archived by one exact successful CI build.

`application.pkr.hcl` is shared by all applications. Each application directory
contains only its runtime installation and image-validation script.

The resulting AMI and `/etc/otms/<application>-image-manifest.json` retain the
Git commit, branch, Jenkins job/build and artifact SHA-256 used to create it.
