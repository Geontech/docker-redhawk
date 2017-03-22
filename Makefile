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
	redhawk/gpp
	# redhawk/gpp \
	# redhawk/usrp \
	# redhawk/rtl2832u \
	# redhawk/webserver
all_images := $(repo) $(omni) $(runtime) $(redhawk_images)

linked_scripts := omniserver domain sdrroot login

# Macros for querying an image vs. building one.
image_check = docker images -q $1
image_build = $(if $(strip $(shell $(call image_check, $1))),, \
	docker build --rm \
		-f ./Dockerfiles/$(subst redhawk/,,$1).Dockerfile \
		-t $1 \
		./Dockerfiles \
	)

.PHONY: all clean images $(all_images) scripts

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

# Groups, all
images: $(redhawk_images)
scripts: $(linked_scripts)
all: images scripts

# Cleaner
clean:
	@echo Removing script links
	@rm -f $(linked_scripts)
	reversed=$(redhawk_images) $(runtime) $(omni) $(repo)
	$(foreach image,$(reversed),\
		$(if $(strip $(shell $(call image_check, $(image)))),\
			$(shell echo Stopping and removing any containers for $(image)) ; \
			$(foreach container,$(shell docker -qa --filter="ancestor=$(image)"), \
				$(shell echo ->    Stopping: $(container)) ; \
				$(shell docker stop $(container)) ; \
				$(shell echo ->    Removing: $(container)) ; \
				$(shell docker rm $(container)) ; \
				) ; \
			$(shell echo Removing image: $(image)) ; \
			$(shell docker rmi $(image)) ; \
			,) \
		)
	@echo **** DO ANY OF THESE LOOK FAMILIAR? ****
	$(shell docker volume ls -q)
	@echo You will need to remove them manually \(docker volume rm VOLUME\)