#!/bin/bash

# Support building a debirf project in stages, using a modified version of debirf

function msg()
{
    echo "${*}" 1>&2
}

function err()
{
    msg "ERROR: ${*}"
}

function run()
{
    msg "Run: ${*}"
    "${@}"
}

function die()
{
    err "${*}"
    exit 1
}

function info()
{
    msg "INFO: ${*}"
}

function warn()
{
    msg "WARN: ${*}"
}

function verbose()
{
    if (( VERBOSE ))
    then
        msg "VERBOSE: ${*}"
    fi
}

function usage()
{
    echo "Usage: ${0##*/} [--help] [--force] [--clean] [--stage<n>]"
}

function process_args()
{
    local arg
    for arg in "${@}"
    do
        case "${arg}" in
            -h|-help|--help|help)
                usage
                exit 0
                ;;
            -f|-force|--force|force)
                force=1
                ;;
            -c|-clean|--clean|clean)
                clean=1
                ;;
            -r|-retry|--retry|retry)
                clean=0
                ;;
            --stage=0)
                set -a
                STAGE_ROOT=true
                STAGE_MODULES=false
                STAGE_INITRD=false
                set +a
                ;;
            # stage1, stage2 execute modules but may be using different module dirs
            --stage=1|--stage=2)
                set -a
                STAGE_ROOT=false
                STAGE_MODULES=true
                STAGE_INITRD=false
                set +a
                ;;
            --stage=3)
                set -a
                STAGE_ROOT=false
                STAGE_MODULES=true
                STAGE_INITRD=true
                set +a
                ;;
            --all)
                set -a
                STAGE_ROOT=true
                STAGE_MODULES=true
                STAGE_INITRD=true
                set +a
                ;;

            make|enter|check|makeiso)
                mode="${arg}"
                ;;
            shell)
                mode="shell"
                ;;
            *)
                if [[ -z "${profile}" && -d "${arg}" ]]
                then
                    profile="${arg}"
                else
                    usage
                    exit 1
                fi
                ;;
        esac
    done

    [[ -n "${DEBIRF_MODULES}" ]] || STAGE_MODULES=false

    [[ -n "${mode}" ]] || mode="make"
    [[ -n "${profile}" ]] || profile="/debirf/project"

    export DEBIRF_PROFILE="${profile}"

    if [[ "${mode}" == "make" ]]
    then
        if (( output_exists ))
        then
            if (( force ))
            then
                if (( clean ))
                then
                    flags+=("-n") # create new root
                else
                    flags+=("-o") # overwrite
                fi
            else
                flags+=("-s")
            fi
        else
            flags+=("-n") # create new
        fi
    fi

    if [[ -z "${DEBIRF_COMMON}" && -f "/debirf/project/common" ]]
    then
        export DEBIRF_COMMON="/debirf/project/common"
    fi

    return 0
}


function go()
{
    # Fix for debootstrap bug - system install does not find libsystemdsyared-241.so
    export LD_LIBRARY_PATH="/lib/systemd"

    if [[ "${mode}" == "shell" ]]
    then
        bash -i
        exit $?
    fi

    local -a cmd=("debirf" "${mode}" "${DEBIRF_PROFILE}" "${flags[@]}")

    if ! run "${cmd[@]}"
    then
        err "FAIL! [${cmd[*]}"
        if [[ -f "${LOG}" ]]
        then
            cat "${LOG}"
            return 1
        else
            return 1
        fi
    else
        return 0
    fi
}

function enter_profile()
{
    if [[ -n "${DEBIRF_PROFILE}" ]]
    then
        cd "${DEBIRF_PROFILE}" || die "Could not enter debirf profile ${DEBIRF_PROFILE}"
    fi
}

function load_config()
{
    set -a
    if [[ -f debirf.conf ]]
    then
        . debirf.conf
    else
        info "No debirf.conf. Environment variables must be provided instead."
    fi
    set +a
}

function generate_config()
{
    python3 -c 'import os; import sys; import jinja2; sys.stdout.write(jinja2.Template(sys.stdin.read()).render(env=os.environ))' \
        < debirf.conf.j2 \
        > debirf.conf
}

function main()
{
    local -a flags=()
    local -a mode=""
    local -a profile=""

    process_args "${@}"

    enter_profile

    #if [[ -f debirf.conf.j2 ]] && ! [[ -f debirf.conf ]]
    #then
    #    generate_config
    #fi
    load_config

    enter_profile

    # [[ -d "${DEBIRF_PROFILE}" ]] || die "No DEBIRF_PROFILE specified."
    set | egrep ^DEBIRF | sort

    [[ -d "${DEBIRF_BUILDD}" ]] || die "No DEBIRF_BUILDD specified."

    local VERBOSE="${VERBOSE:-0}"
    local LOG="${DEBIRF_BUILDD}/root/debootstrap/debootstrap.log"

    output_exists=0
    [[ -d "${DEBIRF_BUILDD}" ]] && output_exists=1

    go
}

main "${@}"
