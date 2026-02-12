FROM ubuntu:22.04

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"

# 1. Install Dependencies
RUN apt-get update && apt-get install -y \
    git wget build-essential cmake pkg-config unzip \
    qt6-base-dev libqt6svg6-dev qt6-tools-dev qt6-tools-dev-tools \
    qt6-l10n-tools qt6-translations-l10n \
    libgl1-mesa-dev libglu1-mesa-dev libxkbcommon-dev \
    ngspice adms software-properties-common gnupg2 sudo \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Wine for QucsStudio
RUN dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -nc -P /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable

# 3. BUILD QUCS-S (Native Linux)
RUN git clone https://github.com/ra3xdh/qucs_s.git /tmp/qucs_s && \
    cd /tmp/qucs_s && mkdir build && cd build && \
    cmake .. && make -j$(nproc) && \
    make install && \
    rm -rf /tmp/qucs_s

# 4. DOWNLOAD & INSTALL QUCSSTUDIO (Windows via Wine)
RUN mkdir -p /opt/qucsstudio && \
    wget https://dd6um.darc.de/QucsStudio/uSimmics-5v9.zip -O /tmp/qucsstudio.zip && \
    unzip /tmp/qucsstudio.zip -d /opt/qucsstudio && \
    rm /tmp/qucsstudio.zip

# 5. Setup User & Comfort Layer
RUN useradd -m builder && \
    echo "builder ALL=(root) NOPASSWD:ALL" > /etc/sudoers && \
    usermod -aG video,audio builder

# Updated Launcher to prevent loops
RUN echo '#!/bin/bash\n\
if [ "$1" == "studio" ]; then\n\
    wine /opt/qucsstudio/bin/qucs.exe\n\
elif [ "$1" == "qucs-s" ]; then\n\
    /usr/local/bin/qucs-s\n\
else\n\
    # This is for the "Stay Alive" mode\n\
    tail -f /dev/null\n\
fi' > /usr/local/bin/qucs-launch && \
    chmod +x /usr/local/bin/qucs-launch

# Pre-configure Qucs-S paths
RUN mkdir -p /home/builder/.config/qucs-s && \
    echo '[ProgPaths]\nNgspicePath=/usr/bin/ngspice\nADMSPath=/usr/bin/admsXml' > /home/builder/.config/qucs-s/qucs-s.conf && \
    echo "alias studio='wine /opt/qucsstudio/uSimmics/bin/qucs.exe'" >> /home/builder/.bashrc && \
    echo "alias qucs='qucs-s'" >> /home/builder/.bashrc && \
    chown -R builder:builder /home/builder/

USER builder
WORKDIR /home/builder
ENV WINEPREFIX="/home/builder/.wine"
ENV WINEARCH=win32

# Trigger wine initialization during build to save time later
RUN wineboot --init

CMD ["qucs-launch"]
