# 离线使用说明

适用对象：要把本库带到不能联网的电脑上的人。

## 1. 在联网电脑上准备

如果你是从 GitHub 获取本库，git 仓库里只有脚本和清单，大文件在 Release 中。克隆后把它们下载并组装回来：

```bash
git clone https://github.com/yuriev315/linux-offline-installation-resource-library.git Linux_Offline_Installation_Resource_Library
cd Linux_Offline_Installation_Resource_Library
bash 10_INSTALLATION_SCRIPTS/recovery/assemble_from_github_release.sh     # 约 13 GB，可断点续传
bash 10_INSTALLATION_SCRIPTS/recovery/fetch_url_placeholders.sh           # 约 1.2 GB，从发布方下载受许可限制的文件
```

Windows 上用同名的 `.ps1` 脚本。第一个脚本可以用 `--only iso|wsl|apt|runtime` 只取一部分，第二个可以用 `--only vmware|wsl|vscode`。

**WSL2 必须运行第二个脚本**，否则没有 WSL 安装包。VMware 安装程序需要 Broadcom 账户，脚本会列出下载地址，由你手动下载，见 `03_VMWARE/workstation_installers/HOW_TO_OBTAIN.md`。

## 2. 校验

```bash
bash 10_INSTALLATION_SCRIPTS/integrity_verification/verify_library.sh
```

结果应为 `RESULT: OK`。这个脚本不需要联网。它会检查：

- 所有文件的 SHA256；
- Ubuntu 官方校验列表的 GPG 签名；
- 所有 `.deb` 是否可读；
- 每个 `.deb` 是否与 Ubuntu 官方签名索引一致。

## 3. 复制

把整个目录复制到 U 盘或移动硬盘。全部内容约 15 GB，建议使用 exFAT 或 NTFS 格式；FAT32 放不下超过 4 GB 的 ISO。

## 4. 在离线电脑上使用

按 [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) 操作。脚本的默认行为：

- **只用本地仓库。** 安装时 APT 只读取本库，不会尝试联网，也不会修改你现有的软件源文件。
- **依赖不足时明确报错，且不改动系统。** 退出码 20 表示本库无法满足请求，错误信息会列出缺少的依赖。

想让普通的 `apt install` 也能使用本库，运行：

```bash
sudo 10_INSTALLATION_SCRIPTS/apt_offline/setup_local_repo.sh           # 添加
sudo apt-get update                                                    # 其他源可能报连接错误，离线时可忽略
sudo 10_INSTALLATION_SCRIPTS/apt_offline/setup_local_repo.sh --remove  # 移除，只删除该脚本创建的两个文件
```

## 5. 本地 APT 仓库的范围

这是一个按依赖闭包筛选的子集，**不是 Ubuntu 完整镜像**。

- **包含：** 分组清单里的软件包及全部递归依赖，还有从出厂 Server、Desktop、WSL 系统升级所需的包。详见 `12_CHECKSUMS_AND_METADATA/PACKAGE_DEPENDENCIES.csv`。
- **不包含：** 清单之外的软件，例如 `apt install nginx` 会报错。
- **更新：** 这是构建当日（2026-11-05）的快照，之后发布的安全更新不在其中。`10_INSTALLATION_SCRIPTS/apt_offline/build/` 下有构建脚本，但它们依赖构建机上未纳入 git 的私有 APT 配置和系统基线（`.tools/`），**目前不能在新克隆上直接运行**，只能作为更新时的参考。

## 6. 仓库的签名方式

Ubuntu 的官方签名只覆盖完整索引，子集无法沿用，所以本地仓库索引用本库自己的密钥签名，公钥在 `04_APT_OFFLINE_REPOSITORY/repository_keys/offline-repo-signing-key.gpg`。私钥不随库分发。

软件包的来源由 `verify_repo_against_official.py` 单独证明：它用 Ubuntu 官方公钥验证官方索引，再逐个核对 `.deb` 的 SHA256。
