# SPDX-License-Identifier: MIT
# Copyright (C) 2020 Tobias Gruetzmacher
# Copyright (C) 2022 Fredrik Noring

FROM gentoo/portage:latest as portage
FROM gentoo/stage3:latest as gentoo

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

WORKDIR /srv

COPY configs configs
COPY initramfs initramfs
COPY patches patches
COPY scripts scripts

RUN scripts/main

WORKDIR /

CMD ["/bin/bash"]
