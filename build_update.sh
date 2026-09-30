#!/bin/bash
# build_update.sh - 基于官方 update.tar 构建定制 update.tar
# 用法: bash build_update.sh [VERSION] [DT_ID]
# 示例: bash build_update.sh 21.3-Omega g12a_s905x2_2g
#
# 环境变量（优先级低于命令行参数）:
#   VERSION  目标版本，默认 21.3-Omega
#   DT_ID    要覆盖的设备树名称，默认为 g12a_s905x2_2g
#            需与 /usr/share/bootloader/device_trees/ 下的文件名（不含 .dtb）一致
#   DTB_FILE 用于覆盖的 dtb 源文件路径，默认 ./e900v22d.dtb

set -e

VERSION="${1:-${VERSION:-21.3-Omega}}"
DT_ID="${2:-${DT_ID:-g12a_s905x2_2g}}"
DTB_FILE="${DTB_FILE:-e900v22d.dtb}"

DEVICE="Amlogic-ng"
SRC_TAR="CoreELEC-${DEVICE}.arm-${VERSION}.tar"
TOP_DIR="CoreELEC-${DEVICE}.arm-${VERSION}"
OUT_TAR="CoreELEC-${DEVICE}.arm-${VERSION}-custom.tar"
SRC_URL="https://github.com/CoreELEC/CoreELEC/releases/download/${VERSION}/${SRC_TAR}"

REPO_ROOT="$(pwd)"
WORKDIR="${REPO_ROOT}/update_build"

echo "==> 配置:"
echo "    VERSION  = ${VERSION}"
echo "    DT_ID    = ${DT_ID}"
echo "    DTB_FILE = ${DTB_FILE}"

# 检查 dtb 源文件是否存在
if [ ! -f "${REPO_ROOT}/common-files/${DTB_FILE}" ]; then
    echo "❌ 未找到 dtb 文件: ${REPO_ROOT}/common-files/${DTB_FILE}"
    exit 1
fi

# Cleanup WORKDIR
rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

echo "==> [1/8] 下载官方 update.tar: ${SRC_TAR}"
wget -q -O "${SRC_TAR}" "${SRC_URL}"

echo "==> [2/8] 解包 tar"
tar -xf "${SRC_TAR}"

echo "==> [3/8] 解压 SYSTEM (SquashFS)"
cd "${TOP_DIR}/target"
rm -rf squashfs-root
unsquashfs -d squashfs-root SYSTEM

echo "==> [4/8] 替换 dtb: ${DT_ID}.dtb"
DTB_DIR="squashfs-root/usr/share/bootloader/device_trees"
mkdir -p "${DTB_DIR}"

if [ -f "${DTB_DIR}/${DT_ID}.dtb" ]; then
    echo "    覆盖已有 dtb: ${DT_ID}.dtb"
else
    echo "    ⚠️  官方 tar 中不存在 ${DT_ID}.dtb，将新增该文件"
fi

cp -f "${REPO_ROOT}/common-files/${DTB_FILE}" "${DTB_DIR}/${DT_ID}.dtb"
chmod 644 "${DTB_DIR}/${DT_ID}.dtb"

# 可选: 若原有 dtb.img 存在于 bootloader 目录，也一并替换
# （update.sh 处理 /dev/coreelec 分区时会 rm dtb.img，无需担心；
#   但若某些设备走 cp 分支，则 bootloader 目录下同名文件会被使用）
BOOTLOADER_DIR="squashfs-root/usr/share/bootloader"
if [ -f "${BOOTLOADER_DIR}/${DT_ID}_dtb.img" ]; then
    cp -f "${REPO_ROOT}/common-files/${DTB_FILE}" "${BOOTLOADER_DIR}/${DT_ID}_dtb.img"
    chmod 644 "${BOOTLOADER_DIR}/${DT_ID}_dtb.img"
fi

echo "==> [5/8] 应用其它魔改"
# ===== 在这里放入你 build.sh 中的其余定制（fs-resize / hwdb / 蓝牙固件等）=====
# 示例：
echo "Copying fs-resize script"
if [ -f "${REPO_ROOT}/common-files/fs-resize" ]; then
    mkdir -p squashfs-root/usr/lib/libreelec/
    cp -f "${REPO_ROOT}/common-files/fs-resize" squashfs-root/usr/lib/libreelec/fs-resize
    chmod 0755 squashfs-root/usr/lib/libreelec/fs-resize
fi
#
echo "Copying hwdb files"
if [ -f "${REPO_ROOT}/common-files/CMCC_Voice_Remote.hwdb" ]; then
    mkdir -p squashfs-root/usr/config/hwdb.d
    cp -f "${REPO_ROOT}/common-files/CMCC_Voice_Remote.hwdb" squashfs-root/usr/config/hwdb.d/
    chmod 0644 squashfs-root/usr/config/hwdb.d/CMCC_Voice_Remote.hwdb
fi
#
# mkdir -p squashfs-root/usr/lib/firmware/brcm
# ln -sf ../brcmfmac43455-sdio.bin \
#     squashfs-root/usr/lib/firmware/brcm/brcmfmac43455-sdio.txt
systemd_path="squashfs-root/usr/lib/systemd/system"
firmware_path="squashfs-root/usr/lib/kernel-overlays/base/lib/firmware"
echo "Copying firmware files (Symbolic links)"
ln -s ../rtl_bt/rtl8761b_config.bin "${firmware_path}/rtlbt/rtl8761b_config"
ln -s ../rtl_bt/rtl8761b_fw.bin "${firmware_path}/rtlbt/rtl8761b_fw"
ln -s ../rtkbt-firmware-aml.service "${systemd_path}/multi-user.target.wants/rtkbt-firmware-aml.service"
# ===== 魔改结束 =====

echo "==> [6/8] 重新打包 SYSTEM (SquashFS)"
rm -f SYSTEM
mksquashfs squashfs-root SYSTEM \
    -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 -b 524288 -no-xattrs

md5sum SYSTEM > SYSTEM.md5

echo "==> [7/8] 重新打包为 tar"
cd "${WORKDIR}"
tar -cf "${OUT_TAR}" "${TOP_DIR}"

echo "==> [8/8] 生成 SHA256"
sha256sum "${OUT_TAR}" > "${OUT_TAR}.sha256"

echo ""
echo "✅ 构建完成:"
echo "   ${PWD}/${OUT_TAR}"
