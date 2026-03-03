shell_source(name="build-script", source="build.sh")

shell_command(
    name="fedora-43-amd64-qcow2",
    command=(
        "wget https://fedora-mirror-atl.gigsouth.com/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2 "
        "-O fedora-43-generic-amd64.qcow2"
    ),
    tools=["wget"],
    output_files=["./fedora-43-generic-amd64.qcow2"],
    log_output=True,
)

run_shell_command(
    name="build",
    command="CHROOT={chroot} bash ./build.sh",
    execution_dependencies=[
        "//:common",
        ":build-script",
        ":fedora-43-amd64-qcow2",
    ],
)
