# debirf-builder
docker image for building debirf initrd images on non-debian systems

## What is it?

A hacked / modified version of 'debirf', with some changes to:

    - allow to build a debirf initramfs using a docker container
      rather than needing to run on a debian system
    - breaks up the build into several stages for easier re-execution / iterative development
        - stage0 - performs the debootstrap (the slowest part)
        - stage1 - prepares the root, apt, and creates a snapshot archive for easy rollback
        - stage2 - runs your debirf modules
        - stage3 - finalises the directory and packs the initramfs file
    - most modules should be developed in stage2
        - if a module is not idempotent you can roll back to the stage1 root filesystem by running *make rollback*
    - additionally it allows to add extra functions to a lib file (lib/lib.sh) which will be available to all debirf modules
    - It has a custom initrd nest-init init script which:
        - provides some info while booting unless quiet mode is enabled, and
        - is very quiet while booting if quiet mode is enabled, which assists in reducing text before a boot splash takes over
        - adds break=err option to break to a shell if the unpack fails (which can happen if you've changed the compression/decompression options, or if you are running with very low RAM)

