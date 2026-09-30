#!/bin/bash
# build_update.sh - 基于官方 update.tar 构建定制 update.tar
# 用法: bash build_update.sh [VERSION]
# 示例: bash build_update.sh 21.3-Omega

set -e

VERSION="${1:-21.3-Omega}"
DEVICE="Amlogic-ng"
SRC_TAR="CoreELEC-${DEVICE}.arm-${VERSION}.tar"
TOP_DIR="CoreELEC-${DEVICE}.arm-${VERSION}"
OUT_TAR="CoreELEC-${DEVICE}.arm-${VERSION}-e900v22d.tar"
SRC_URL="https://github.com/CoreELEC/CoreELEC/releases/download/${VERSION}/${SRC_TAR}"

# Cleanup
WORKDIR="${PWD}/update_build"
rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"

cd "${WORKDIR}"

echo "==> [1/7] 下载官方 update.tar: ${SRC_TAR}"
wget -q --show-progress -O "${SRC_TAR}" "${SRC_URL}"

echo "==> [2/7] 解包 tar"
tar -xf "${SRC_TAR}"

echo "==> [3/7] 解压 SYSTEM (SquashFS)"
cd "${TOP_DIR}/target"
rm -rf squashfs-root
unsquashfs -d squashfs-root SYSTEM

echo "==> [4/7] 应用魔改"
# ===== 在这里应用你的魔改 =====
# 解压后的根文件系统位于 ./squashfs-root, 对应机顶盒上的 /
# 示例（请按你 build.sh 中的实际逻辑调整）：
#
# if [ -f "../../../fs-resize" ]; then
#     cp -f "../../../fs-resize" squashfs-root/usr/lib/libreelec/fs-resize
#     chmod 755 squashfs-root/usr/lib/libreelec/fs-resize
# fi
#
# if [ -f "../../../CMCC_Voice_Remote.hwdb" ]; then
#     mkdir -p squashfs-root/usr/config/hwdb.d
#     cp -f "../../../CMCC_Voice_Remote.hwdb" squashfs-root/usr/config/hwdb.d/
#     chmod 644 squashfs-root/usr/config/hwdb.d/CMCC_Voice_Remote.hwdb
# fi
#
# mkdir -p squashfs-root/usr/lib/firmware/brcm
# ln -sf ../brcmfmac43455-sdio.bin \
#     squashfs-root/usr/lib/firmware/brcm/brcmfmac43455-sdio.txt
# ===== 魔改结束 =====


echo "==> [5/7] 重新打包 SYSTEM (SquashFS)"
# 使用与官方一致的压缩参数；若不确定，可用 unsquashfs -s SYSTEM 查看原参数
rm -f SYSTEM
mksquashfs squashfs-root SYSTEM \
    -comp lzo -b 524288 -no-xattrs -noappend

# 重新生成 SYSTEM.md5
md5sum SYSTEM > SYSTEM.md5

echo "==> [6/7] 重新打包为 tar"
cd "${WORKDIR}"
# 保持顶层目录结构，tar 内路径为 TOP_DIR/...
tar -cf "${OUT_TAR}" "${TOP_DIR}"

echo "==> [7/7] 生成 SHA256"
sha256sum "${OUT_TAR}" > "${OUT_TAR}.sha256"

echo ""
echo "✅ 构建完成:"
echo "   ${PWD}/${OUT_TAR}"
echo "   ${PWD}/${OUT_TAR}.sha256"
