# VendoredImages

This repository is used to vendor generic cloud images and prepare them for use in cloud environments. The main goals are to:

- Ensure the `qemu-guest-agent` package is installed in all images.
- Reset the machine ID to avoid duplicate IDs across instances.
- Clean up any potential cloud-init logs to ensure a fresh initialization on first boot.
- Clean up the `/var/log` directory to remove any residual logs from the image build process.

These steps help guarantee that each image is ready for deployment and will initialize cleanly in new environments.
