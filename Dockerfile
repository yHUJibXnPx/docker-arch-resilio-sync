# === 第一阶段：构建工坊 ===
# ubuntu 滚动版，追求新颖，不稳定
FROM docker.io/library/ubuntu:rolling AS builder

# 构建参数，只有构建阶段有效，构建完成后消失
# init_system.sh 所需临时环境变量
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ='Asia/Shanghai'
# Docker 提供的环境比如 linux/arm64 linux/arm64 linux arm64
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

# 固化运行环境变量，全局构建和容器运行都可用，字符支持，安装目录，以及启动路径
# init_system.sh 所需固化环境 LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8 \
    LC_CTYPE=zh_CN.UTF-8

# 添加常用LABEL（根据需要修改）添加标题 版本 作者 代码仓库 镜像说明，方便优化
LABEL org.opencontainers.image.description='安装 Resilio Sync 封装特殊需求自用测试容器' \
      org.opencontainers.image.title='Multi-arch Resilio Sync' \
      org.opencontainers.image.version='1.0.0' \
      org.opencontainers.image.authors='yHUJibXnPx <bXnPxyHUJi@outlook.com>' \
      org.opencontainers.image.source='https://github.com/yHUJibXnPx/docker-arch-resilio-sync' \
      org.opencontainers.image.licenses='MIT'

# 复制所有脚本到 /usr/local/bin（保持工作目录干净）
# 执行安装与配置脚本（全部以 root 执行）
# 并用 --mount=type=bind,source=scripts,target=/usr/local/src/scripts 替代等效且不会产生层级
#COPY scripts/ /usr/local/src/scripts

# 复制离线资源如果存在的话，随着加入的东西越多，会增加层级大小，所以注释。
# 并用 --mount=type=bind,source=sources,target=/usr/local/src/sources 替代等效且不会产生层级
#COPY sources/ /usr/local/src/sources

# 执行 初始化 安装
# 保留日志脚本 common.sh
# 启动脚本 start_test.sh
RUN --mount=type=bind,source=scripts,target=/usr/local/src/scripts \
    --mount=type=bind,source=sources,target=/usr/local/src/sources \
    echo "build=${BUILDPLATFORM} target=${TARGETPLATFORM} os=${TARGETOS} arch=${TARGETARCH}" && \
    cp -fv /usr/local/src/scripts/*.sh /usr/local/bin/ && \
    cd /usr/local/bin/ && \
    chmod -v a+x *.sh && \
    analyze_size.sh before-install && \
    init_system.sh && \
    install_resilio-sync.sh && \
    analyze_size.sh after-install && \
    clean.sh && \
    rm -fv init_system.sh install_resilio-sync.sh clean.sh && \
    analyze_size.sh after-clean

# === 第二阶段：真空封存 (终极单层) ===
# scratch 是一个绝对为空的镜像
FROM scratch

# 从 builder 阶段直接把整个根文件系统拷贝过来
# 这一步操作会把之前几十层的所有变更，合并为一层
COPY --from=builder / /
# scratch ENV 需要固化的临时环境
ARG BUILD_HOME=/root
ARG BUILD_PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
ARG TERM=xterm

ENV LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:' \
    TERM=${TERM} \
    HOME=${BUILD_HOME} \
    SHELL=/bin/bash \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8 \
    LC_CTYPE=zh_CN.UTF-8 \
    PATH=${BUILD_PATH}

# 添加常用LABEL（根据需要修改）添加标题 版本 作者 代码仓库 镜像说明，方便优化
LABEL org.opencontainers.image.description='安装 Resilio Sync 封装特殊需求自用测试容器' \
      org.opencontainers.image.title='Multi-arch Resilio Sync' \
      org.opencontainers.image.version='1.0.0' \
      org.opencontainers.image.authors='yHUJibXnPx <bXnPxyHUJi@outlook.com>' \
      org.opencontainers.image.source='https://github.com/yHUJibXnPx/docker-arch-resilio-sync' \
      org.opencontainers.image.licenses='MIT'

# 设置工作目录 '/root/Resilio Sync' 仅用于 Resilio Sync 数据挂载（保持干净）
WORKDIR /root/'Resilio Sync'

# 使用 tini 作为入口，调用 entrypoint 脚本或者直接启动 /usr/local/bin/start_test.sh
ENTRYPOINT ["tini", "--"]

# 脚本执行
CMD [ "/usr/local/bin/start_resilio-sync.sh", "--config", "/usr/local/etc/resilio-sync/sync.conf" ]
