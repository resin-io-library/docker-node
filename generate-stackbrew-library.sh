#!/bin/bash
set -e
set -o pipefail

# Generate library file.
# $1 : device type
# $2 : distribution
# $3 : variants
function generate_library(){
	if [ $2 == 'debian' ]; then
		lib_name="$1-node"
	else
		lib_name="$1-$2-node"
	fi
	path="$1/$2"

	# Don't export rpi-alpine-node library
	if [ $1 == 'rpi' ] && [ $2 == 'alpine' ]; then
		continue
	fi

	# Export armhf-alpine-node instead of armv7hf-alpine-node
	if [ $1 == 'armv7hf' ] && [ $2 == 'alpine' ]; then
		lib_name="armhf-alpine-node"
	fi

	cd $path
	versions=( */ )
	versions=( "${versions[@]%/}" )
	cd -

	url='git://github.com/resin-io-library/docker-node'
	echo '# maintainer: Joyent Image Team <image-team@joyent.com> (@joyent)' > $lib_name
	echo '# maintainer: Trong Nghia Nguyen - resin.io <james@resin.io>' >> $lib_name

	for version in "${versions[@]}"; do
		commit="$(git log -1 --format='format:%H' -- "$path/$version/slim")"
		fullVersion="$(grep -m1 'ENV NODE_VERSION ' "$path/$version/slim/Dockerfile" | cut -d' ' -f3)"
		if [ $version == 'default' ]; then
			versionAliases=( $fullVersion )
		else
			versionAliases=( $fullVersion $version ${aliases[$fullVersion]} )
		fi

		echo >> $lib_name

		for variant in $3; do
			commit="$(git log -1 --format='format:%H' -- "$path/$version/$variant")"
			echo >> $lib_name
			for va in "${versionAliases[@]}"; do
				if [ "$va" = 'latest' ]; then
					va="$variant"
				else
					va="$va-$variant"
				fi
				echo "$va: ${url}@${commit} $path/$version/$variant" >> $lib_name
			done
		done
	done
}

declare -A aliases
aliases=(
	[6.5.0]='6 latest'
)

defaultVersion='0.10.22'

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

repo=${PWD##*/}

devices=( "$@" )
if [ ${#devices[@]} -eq 0 ]; then
	devices=( */ )
fi
devices=( "${devices[@]%/}" )

for device in "${devices[@]}"; do

	cd $device
	distros=( */ )
	distros=( "${distros[@]%/}" )
	cd ..

	for distro in "${distros[@]}"; do
		# Debian
		if [ $distro == 'debian' ]; then
			generate_library "$device" "$distro" "slim"
		fi
		# Alpine
		if [ $distro == 'alpine' ]; then
			generate_library "$device" "$distro" "slim"
		fi
	done
done
