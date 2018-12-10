#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Shamelessly borrowed from android's envsetup.sh.
function getrootdir
{
    local TOPFILE=build/Makefile
    if [[ -n "$ROOTDIR" && -f "$ROOTDIR/$TOPFILE" ]]; then
        # The following circumlocution ensures we remove symlinks from ROOTDIR.
        (cd $ROOTDIR; PWD= /bin/pwd)
    else
        if [[ -f $TOPFILE ]]; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE=$PWD
            local R=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                \cd ..
                R=`PWD= /bin/pwd -P`
            done
            \cd $HERE
            if [ -f "$R/$TOPFILE" ]; then
                echo $R
            fi
        fi
    fi
}

export ROOTDIR="$(getrootdir)"
source ${ROOTDIR}/board/project.sh
export OUT="${ROOTDIR}/out"
export PRODUCT_OUT="${OUT}/target/product/${PROJECT_NAME}"
export HOST_OUT="${OUT}/host/linux-x86"
export ROOT_OUT="${OUT}/root"
export BUILDTAB="${OUT}/buildtab"

export PATH="${PATH}:${HOST_OUT}/bin:${ROOTDIR}/build:${ROOTDIR}/board"

function m
{
    local target="build"

    if [[ -f /.dockerenv ]]; then
        target="sub-build"
    fi

    pushd "${ROOTDIR}" >/dev/null
    log.sh $target started m "$@"

    make -f "${ROOTDIR}/build/Makefile" "$@"

    if [[ "$?" != 0 ]]; then
        log.sh $target failed
    else
        log.sh $target finished
    fi
    popd >/dev/null
}

function mm
{
    local module="$1"; shift
    local target="build"

    if [[ -z "${module}" ]]; then
        echo "Usage: mm <modulename> [<target>]"
        echo "Where"
        echo "  modulename is one of the makefiles in \$ROOTDIR/build"
        echo "  target is an optional target to make"
        return 1
    fi

    if [[ ! -f "${ROOTDIR}/build/${module}.mk" ]]; then
        echo "mm: ${module} is not a valid module."
        return 1
    fi

    if [[ -f /.dockerenv ]]; then
        target="sub-build"
    fi

    pushd "${ROOTDIR}" >/dev/null
    log.sh $target started mm "$@"
    make -f "${ROOTDIR}/build/${module}.mk" "$@"
    if [[ "$?" != 0 ]]; then
        log.sh $target failed
    else
        log.sh $target finished
    fi
    popd >/dev/null
}

if builtin complete >/dev/null 2>/dev/null; then
    function _mm_modules
    {
        echo "${ROOTDIR}"/build/*.mk \
            | xargs -n1 basename \
            | sed 's/.mk$//' \
            | grep -v 'template' \
            | grep -v 'preamble'
    }

    function _mm_module_targets
    {
        local module="$1"; shift

        mm "${module}" targets \
           | sed 's/ .*$//'
    }

    function _mm
    {
        local cur=${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=()
        if [[ $COMP_CWORD -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "$(_mm_modules)" $cur) )
        fi
        if [[ $COMP_CWORD -eq 2 ]]; then
            COMPREPLY=( $(compgen -W "$(_mm_module_targets ${COMP_WORDS[1]})" $cur) )
        fi
    }

    complete -F _mm mm
fi

if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    unset JUMP_TARGETS
    declare -Ax JUMP_TARGETS
    JUMP_TARGETS[.]="."
    JUMP_TARGETS[board]="${ROOTDIR}/board"
    JUMP_TARGETS[top]="${ROOTDIR}"
    JUMP_TARGETS[rootdir]="${ROOTDIR}"
    JUMP_TARGETS[out]="${OUT}"
    JUMP_TARGETS[product]="${PRODUCT_OUT}"
    JUMP_TARGETS[host]="${HOST_OUT}"
    JUMP_TARGETS[root]="${ROOT_OUT}"
    JUMP_TARGETS[build]="${ROOTDIR}/build"
    JUMP_TARGETS[packages]="${ROOTDIR}/packages"

    if [[ -f "${ROOTDIR}/board/jump_targets.sh" ]]; then
      source "${ROOTDIR}/board/jump_targets.sh"
    fi

    function j
    {
        local target="$1"; shift

        if [[ -z "${target}" ]]; then
            cd "${ROOTDIR}"
            return 0
        fi

        if [[ -z "${JUMP_TARGETS[$target]}" ]]; then
            echo "Jump targets are:"
            echo "${!JUMP_TARGETS[@]}"
            return 1
        fi

        cd "${JUMP_TARGETS[$target]}"
    }

    if builtin complete >/dev/null 2>/dev/null; then
        function _j_targets
        {
            echo "${!JUMP_TARGETS[@]}"
        }

        function _j
        {
            local cur=${COMP_WORDS[COMP_CWORD]}
            COMPREPLY=()
            if [[ $COMP_CWORD -eq 1 ]]; then
                COMPREPLY=( $(compgen -W "$(_j_targets)" $cur) )
            fi
        }

        complete -F _j j
    fi
fi

echo ========================================
echo ROOTDIR="${ROOTDIR}"
echo OUT="${OUT}"
echo PRODUCT_OUT="${PRODUCT_OUT}"
echo HOST_OUT="${HOST_OUT}"
echo ROOT_OUT="${ROOT_OUT}"
echo ========================================
echo
echo Type m to build.
