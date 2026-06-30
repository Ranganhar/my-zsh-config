FROM ubuntu:jammy

ARG USER_PASSWD
ARG USER_NAME

ENV container=docker
ENV distro=ubuntu2204
ENV distro_codename=jammy
ENV DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 使用 HTTP 国内源，避免基础镜像缺少 ca-certificates 时 HTTPS 证书校验失败
RUN cat > /etc/apt/sources.list <<'EOF'
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  openssh-server \
  sudo \
  bash \
  zsh \
  git \
  curl \
  wget \
  vim \
  tmux \
  fzf \
  locales \
  unzip \
  zip \
  tar \
  xz-utils \
  gnupg \
  lsb-release \
  iproute2 \
  iputils-ping \
  dnsutils \
  net-tools \
  procps \
  less \
  jq \
  htop \
  build-essential \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  && locale-gen en_US.UTF-8 \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /usr/bin/zsh ${USER_NAME} && \
  echo "${USER_NAME}:${USER_PASSWD}" | chpasswd && \
  usermod -aG sudo ${USER_NAME}

RUN mkdir -p /var/run/sshd && \
  mkdir -p /home/${USER_NAME}/file && \
  chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/file

RUN echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
  echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
  echo "AllowUsers ${USER_NAME}" >> /etc/ssh/sshd_config

WORKDIR /home/${USER_NAME}

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
