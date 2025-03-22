def run(plan):
    plan.print("Building images")

    images = json.decode(read_file("./nix/images.json"))
    configs = {}
    for svc, config in images.items():
        rev = config.get("revision", None)

        image = build_svc_image(
            svc = svc,
            rev = rev,
        )

        configs[svc] = fake_service_config(
            image = image,
        )

    services = plan.add_services(
        configs = configs,
        description = "adding fake services",
    )

    for _, svc in services.items():
        plan.stop_service(
            name = svc.name,
            description = "stopping fake service",
        )

def fake_service_config(image):
    """ This is a fake service config that is used to force building the image.

    It is not used to actually run the service.

    Args:
        image: The image to build.

    Returns:
        A fake service config.
    """
    return ServiceConfig(
        image = image,

        entrypoint = [
            "/bin/sh"
        ],
        cmd = [
            "-c",
            "sleep infinity",
        ],
    )


def build_svc_image(svc, rev):
    """ Builds the service image.

    Args:
        svc: The service name.
        rev: The revision.

    Returns:
        The Nix build spec.
    """

    return NixBuildSpec(
        image_name = "nix-{}:{}".format(svc, rev),
        build_context_dir = "./nix",
        flake_location_dir = ".",
        flake_output = svc,
    )
