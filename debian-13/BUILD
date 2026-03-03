shell_source(name="build-script", source="build.sh")

shell_command(
    name="debian-13-amd64-qcow2",
    command=(
        "wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2 "
        "-O debian-13-generic-amd64.qcow2"
    ),
    tools=["wget"],
    output_files=["./debian-13-generic-amd64.qcow2"],
    log_output=True,
)

run_shell_command(
    name="build",
    command="CHROOT={chroot} bash ./build.sh",
    execution_dependencies=[
        "//:common",
        ":build-script",
        ":debian-13-amd64-qcow2",
    ],
)
