#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

log_info "Starting Resilio Sync environment setup..."

TARGET_FILE=''

# 限定范围以后有其他的再加
case "${TARGETOS}" in
  linux)
    log_info "Supported TARGETOS: ${TARGETOS}"
    case "${TARGETARCH}" in
      arm64)
        log_info "Supported architecture: ${TARGETARCH}"
        TARGET_FILE="${TARGETOS}/${TARGETARCH}/0/resilio-sync_${TARGETARCH}.tar.gz"
        ;;
      amd64)
        TARGETARCH='x64'
        TARGET_FILE="${TARGETOS}/${TARGETARCH}/0/resilio-sync_${TARGETARCH}.tar.gz"
        ;;
      *)
        log_error "Unsupported architecture: ${TARGETARCH}"
        exit 1
        ;;
    esac
    ;;
  # 这本身不用于docker只是用于记录这段代码可能永远不会生效
  darwin)
    TARGETOS=mac
    case "${TARGETARCH}" in
      arm64)
        TARGETARCH=osx
        TARGET_FILE="${TARGETOS}/${TARGETARCH}/0/Resilio-Sync.dmg"
        ;;
      amd64)
        TARGETARCH=osx
        TARGET_FILE="${TARGETOS}/${TARGETARCH}/0/Resilio-Sync.dmg"
        ;;
      *)
        log_error "Unsupported architecture: ${TARGETARCH}"
        exit 1
        ;;
    esac
    ;;
  *)
    log_error "Unsupported TARGETOS: ${TARGETOS}"
    exit 1
    ;;
esac

log_info "TARGETOS: ${TARGETOS}"
log_info "TARGETARCH: ${TARGETARCH}"
log_info "TARGET_FILE: ${TARGET_FILE}"

if [ "${TARGET_FILE}" != "" ];then
  # 拼接下载链接和校验码链接
  URI_DOWNLOAD='https://download-cdn.resilio.com/stable/'$TARGET_FILE
  log_info "Download URL: ${URI_DOWNLOAD}"
else
  log_error "TARGET_FILE is NULL: ${TARGET_FILE}"
  exit 1
fi

# 如果文件不存在
if [[ ! -f "/tmp/$(basename ${TARGET_FILE})" ]]; then
  log_info "Downloading file..."
  # 临时取消 set -e（如果你之前开启了严格模式）防止炸脚本
  set +e
  curl -L -C - --retry 3 --retry-delay 5 --progress-bar -o "/tmp/$(basename ${TARGET_FILE})" "${URI_DOWNLOAD}"
  set -e
fi

# 安装 Resilio Sync
log_info "Installing Resilio Sync..."
tar xfv "/tmp/$(basename ${TARGET_FILE})" -C /usr/local/bin rslsync
chmod -v a+x /usr/local/bin/rslsync
if [[ ! -d "/usr/local/etc/resilio-sync" ]]; then
  log_info "Copy file..."
  cp -frv /usr/local/src/sources/resilio-sync /usr/local/etc/
  cp -fv /usr/local/src/sources/ResilioSyncPro.btskey /usr/local/src
fi

log_info "Resilio Sync setup is complete."
# 临时取消 set -e（如果你之前开启了严格模式）防止炸脚本
set +e
rslsync --version
set -e