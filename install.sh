#!/bin/bash

# setup-rivos-dev.sh
# 安装 Rust 和 QEMU RISC-V 开发环境的脚本

set -e  # 遇到错误立即退出

echo "=== 开始安装 RISC-V 开发环境 ==="

# 更新系统包管理器
echo "更新系统包..."
apt-get update
apt-get upgrade -y

# 安装基础开发工具
echo "安装基础开发工具..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    python3 \
    python3-pip \
    libglib2.0-dev \
    libfdt-dev \
    libpixman-1-dev \
    zlib1g-dev \
    libssl-dev \
    libelf-dev \
    device-tree-compiler \
    flex \
    bison

# 安装 Rust
echo "安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 配置 Rust 环境变量
source $HOME/.cargo/env

# 添加 RISC-V 目标
echo "添加 RISC-V 目标..."
rustup target add riscv64gc-unknown-none-elf
rustup component add rust-src
rustup component add llvm-tools-preview

# 安装 cargo-binutils
echo "安装 cargo-binutils..."
cargo install cargo-binutils

# 安装 QEMU
echo "安装 QEMU..."
apt-get install -y qemu-system-misc qemu-utils

# 验证 QEMU 版本
echo "QEMU 版本信息:"
qemu-system-riscv64 --version

# 验证 Rust 安装
echo "Rust 版本信息:"
rustc --version
cargo --version

# 验证 RISC-V 目标
echo "已安装的 Rust 目标:"
rustup target list | grep installed

# 创建测试项目验证环境
echo "创建测试项目..."
cd /work
if [ ! -d "rivos-test" ]; then
    cargo new rivos-test
    cd rivos-test
    echo '[[bin]]' >> Cargo.toml
    echo 'name = "rivos-test"' >> Cargo.toml
    echo 'path = "src/main.rs"' >> Cargo.toml
    
    cat > src/main.rs << 'EOF'
#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    loop {}
}
EOF

    cat > .cargo/config.toml << 'EOF'
[build]
target = "riscv64gc-unknown-none-elf"

[target.riscv64gc-unknown-none-elf]
rustflags = [
    "-C", "link-arg=-Tsrc/linker.ld",
]
EOF

    cat > src/linker.ld << 'EOF'
OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    . = 0x80000000;
    .text : {
        *(.text .text.*)
    }
}
EOF

    echo "编译测试项目..."
    cargo build
    echo "测试项目编译成功！"
else
    echo "测试项目已存在，跳过创建"
fi

echo ""
echo "=== 安装完成 ==="
echo "Rust 和 QEMU RISC-V 开发环境已成功安装"
echo "可用命令:"
echo "  cargo build --target riscv64gc-unknown-none-elf"
echo "  qemu-system-riscv64 -machine virt -kernel target/riscv64gc-unknown-none-elf/debug/your-binary"