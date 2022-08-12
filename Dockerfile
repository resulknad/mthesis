FROM archlinux/archlinux:base-devel
LABEL maintainer="test.cab <git@test.cab>"

RUN pacman -Syu --needed --noconfirm git wget

# makepkg user and workdir
ARG user=makepkg
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

# Install yay
RUN git clone https://aur.archlinux.org/python39.git \
  && sed -i '/without-ensure/d' python39/PKGBUILD \
  && cd python39 \
  && makepkg -sri --needed --noconfirm \
  && cd \
  # Clean up
  && rm -rf .cache python39


USER root

RUN python3.9 -m ensurepip
RUN wget https://f001.backblazeb2.com/file/dbkthesis/tensorflow-2.8.0-cp39-cp39-linux_x86_64.whl && python3.9 -m pip install tensorflow-2.8.0-cp39-cp39-linux_x86_64.whl && rm tensorflow-2.8.0-cp39-cp39-linux_x86_64.whl
RUN python3.9 -m pip install protobuf==3.19.4 pyyaml
RUN ln -s /usr/bin/python3.9 /usr/bin/python

RUN wget https://f001.backblazeb2.com/file/dbkthesis/data.tar.gz
RUN tar -xvf data.tar.gz

ADD src/ .
RUN mkdir pids && mkdir logs && mkdir hashes

