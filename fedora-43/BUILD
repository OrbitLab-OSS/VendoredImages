shell_source(name="build-script", source="build.sh")
shell_source(name="download-script", source="download.sh")

shell_command(
    name="download-amd64-qcow2",
    command=(
        "wget https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2 "
        "-O fedora-43-generic-amd64.qcow2"
    ),
    tools=["wget"],
    output_files=["./fedora-43-generic-amd64.qcow2"],
    log_output=True,
    timeout=60,
)

#shell_command(
#    name="download-amd64-qcow2",
#    command="bash ./download.sh",
#    tools=["bash", "wget", "tar", "gzip", "qemu-img"],
#    execution_dependencies=[":download-script"],
#    output_files=["./fedora-43-generic-amd64.qcow2"],
#    log_output=True,
#    timeout=60,
#)

run_shell_command(
    name="build",
    command="CHROOT={chroot} bash ./build.sh",
    execution_dependencies=[
        "//:common",
        ":build-script",
        ":download-amd64-qcow2",
    ],
)
