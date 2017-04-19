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
	redhawk/webserver \
        redhawk/usrp
	# redhawk/rtl2832u \
	# redhawk/usrp
all_images := $(repo) $(omni) $(runtime) $(redhawk_images)

linked_scripts := omniserver domain sdrroot login gpp rhide volume-manager webserver usrp

# Macros for querying an image vs. building one.
image_check = $(strip $(shell docker images -q $1))
image_build = $(if $(call image_check,$1),, \
	docker build --rm \
		-f ./Dockerfiles/$(subst redhawk/,,$1).Dockerfile \
		-t $1 \
		./Dockerfiles \
	)

.PHONY: all clean $(all_images)

# Everything
all: $(redhawk_images) $(linked_scripts) $(omni)

# Image building targets
$(repo):
	$(call image_build,$@)	

$(omni) $(runtime): $(repo)
	$(call image_build,$@)

$(redhawk_images): $(runtime)
	$(call image_build,$@)

# Launcher/helper script targets
$(linked_scripts):
	@ln -s scripts/$@.sh ./$@
	@chmod a+x ./$@

# Cleaning methods
reversed := $(redhawk_images) $(runtime) $(omni) $(repo)
stop_container = $(shell docker stop $1 &> /dev/null)
remove_container = $(shell docker rm $1 &> /dev/null)
remove_image = $(shell docker rmi $1 &> /dev/null)

list_containers = $(shell docker ps -qa --filter="ancestor=$1" &> /dev/null)
for_each_container = $(foreach container,$(call list_containers,$1),\
	$(info --> Stopping $1) \
	$(call stop_container,$(container)) \
	$(info --> Removing $1) \
	$(call remove_container,$(container)) \
	)
for_each_image = $(foreach image,$1,\
	$(info Checking $(image)...) \
	$(if $(call image_check,$(image)),\
		$(call for_each_container,$(image)) \
		$(info Removing $(image)) \
		$(call remove_image,$(image)), \
		$(info Nothing to do for $(image)) \
		)\
	)

clean:
	@$(call for_each_image,$(reversed))
	@rm -f $(linked_scripts)
