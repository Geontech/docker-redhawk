# This file is protected by Copyright. Please refer to the COPYRIGHT file
# distributed with this source distribution.
#
# This file is part of Docker REDHAWK.
#
# Docker REDHAWK is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Docker REDHAWK is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/.
#

repo := redhawk/base
omni := redhawk/omniserver
runtime := redhawk/runtime
redhawk_images := \
	redhawk/development \
	redhawk/domain \
	redhawk/gpp \
	redhawk/usrp \
	redhawk/rtl2832u \
	redhawk/webserver
all_images := $(repo) $(omni) $(runtime) $(redhawk_images)

all_scripts := omniserver.sh domain.sh sdrroot.sh

# Macros for querying an image vs. building one.
image_check = docker images -q $1
image_build = $(if $(strip $(shell $(call image_check, $1))),, \
	docker build --rm \
		-f ./Dockerfiles/$(subst redhawk/,,$1).Dockerfile \
		-t $1 \
		./Dockerfiles \
	)

.PHONY: all clean $(all_images)

# Image building targets
$(repo):
	$(call image_build,$@)	

$(omni) $(runtime): $(repo)
	$(call image_build,$@)

$(redhawk_images): $(runtime)
	$(call image_build,$@)

# Launcher script targets
$(all_scripts):
	@ln -s scripts/$@ ./$@

# Do all
all: $(redhawk_images) $(all_scripts)

# Remove containers for the image, then remove the image
cleaner := $(foreach img,$1,\
	$(shell docker ps -a | grep $(img) | awk '{print $$1}' | xargs docker rm && \
			docker rmi $(img)\
		) \
	)

clean:
	$(call cleaner,$(redhawk_images))
	$(call cleaner,$(runtime))
	$(call cleaner,$(omni))
	$(call cleaner,$(repo))
	rm -f $(all_scripts)