# VMware Workstation Pro 26H1u1：获取方法

**这个仓库不含 VMware 安装程序。** 它是 Broadcom 的专有软件，这里只有 `.url` 占位文件，里面写着官方下载地址、文件大小和 SHA256。

## 下载步骤（需要联网和 Broadcom 账户）

1. 注册并登录 [Broadcom Support Portal](https://support.broadcom.com/web/ecx/home)。
2. 打开 [VMware Workstation Pro 免费下载页](https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true)，选择 26H1u1（build 25688693），接受条款后下载。
3. 把文件放进本目录，文件名与 `.url` 占位文件去掉 `.url` 后相同。
4. 运行下面的命令检查，它会核对 SHA256，并列出还缺哪些文件：

   ```bash
   bash 10_INSTALLATION_SCRIPTS/recovery/fetch_url_placeholders.sh --only vmware
   ```

   Windows 上用 `fetch_url_placeholders.ps1 -Only vmware`。

本库测试过的版本的 SHA256：

```text
3d775c3c2153600eef4642f95d519a514ba7e861400bda2598352bff792db473  VMware-Workstation-Full-26H1u1-25688693.exe
da823c853cc7e57be7b9b070c8aed20fe9d75fd519ae6f175ab1dafc7283002e  VMware-Workstation-Full-26H1u1-25688693.x86_64.bundle
```

如果 Broadcom 已发布更新的版本，SHA256 会不同。此时应以 Broadcom 页面上的校验值为准。

## 需要联网的环节

| 环节 | 是否需要联网 |
|---|---|
| 从 Broadcom 下载安装程序 | 需要，且需要账户 |
| 在目标电脑上运行已下载的安装程序 | 不需要：本库在无网卡的 Windows 11 上实测安装成功 |
| 授权 | 不需要输入许可证。Broadcom [官方博客](https://blogs.vmware.com/cloud-foundation/2026/05/14/announcing-vmware-workstation-and-fusion-26h1/)称 26H1 对商业、教育和个人使用免费 |

## 其他文件

Linux 客户机用 Ubuntu 官方的 open-vm-tools，它在本地 APT 仓库里，不需要单独下载。VMware Tools ISO 只有 Windows 客户机才需要，`../vmware_tools` 里有官方直链的占位文件。

## 参考资料

- [26H1 发行说明](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/26H1/release-notes.html)
- [26H1 文档](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/26H1.html)
