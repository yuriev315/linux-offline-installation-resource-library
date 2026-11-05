# VMware Workstation + Ubuntu 24.04 操作指南

适用对象：要用 VMware Workstation Pro 运行 Ubuntu 的用户。安装程序的获取方法见 `../workstation_installers/HOW_TO_OBTAIN.md`。

> 实测情况见 `00_DOCUMENTATION/VERIFICATION_REPORT.md`。

## 0. 安装 VMware

下载后运行 `VMware-Workstation-Full-26H1u1-25688693.exe`，按提示安装。无人值守安装：

```powershell
.\VMware-Workstation-Full-26H1u1-25688693.exe /s /v"/qn EULAS_AGREED=1 AUTOSOFTWAREUPDATE=0 DATACOLLECTION=0 ADDLOCAL=ALL REBOOT=ReallySuppress"
```

## 1. 创建虚拟机

在 Windows PowerShell 中运行：

```powershell
cd <库目录>\10_INSTALLATION_SCRIPTS\ubuntu_vmware
.\create_vmware_vm.ps1 -CheckOnly                                  # 只检查 VMware
.\create_vmware_vm.ps1 -Kind server  -VmDir D:\VMs\ubuntu-server   # 2 核 / 4 GB / 40 GB
.\create_vmware_vm.ps1 -Kind desktop -VmDir D:\VMs\ubuntu-desktop  # 4 核 / 8 GB / 80 GB
```

脚本会创建磁盘、生成 `.vmx` 并挂载对应 ISO，不会覆盖已有目录。用 VMware 打开 `.vmx`（或加 `-PowerOn`），按屏幕提示安装 Ubuntu。

## 2. 把资源库放进虚拟机

可用共享文件夹（第 4 节），也可以把 ISO 以外的目录复制进虚拟机。建议放在 `/opt/Linux_Offline_Installation_Resource_Library`。

## 3. 安装 VMware Tools 和开发环境

Linux 客户机使用 Ubuntu 官方的 open-vm-tools，本库已包含：

```bash
cd /opt/Linux_Offline_Installation_Resource_Library/10_INSTALLATION_SCRIPTS
sudo ubuntu_vmware/setup_vmware_guest.sh --desktop      # Server 不加 --desktop
sudo dependency_installation/install_dev_environment.sh
bash ../13_TESTS/dev_environment/verify_dev_environment.sh
```

重启后剪贴板、拖放和屏幕自适应才会生效（仅 Desktop）。

## 4. 共享目录

1. VMware：虚拟机设置 → 选项 → 共享文件夹 → 总是启用 → 添加。
2. `setup_vmware_guest.sh` 已写好 `/etc/fstab` 的挂载项（原文件备份为 `/etc/fstab.before-offline-library`）。
3. 重启后在 `/mnt/hgfs/<共享名>` 访问。手动挂载：`sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other`。

## 5. 网络

| 模式 | 适合场景 | 设置 |
|---|---|---|
| NAT（模板默认） | 虚拟机只需主动访问外部 | `ethernet0.connectionType = "nat"` |
| 桥接 | 虚拟机要被局域网其他机器访问 | `ethernet0.connectionType = "bridged"` |
| 仅主机 | 完全隔离 | `ethernet0.connectionType = "hostonly"` |

离线环境建议用 NAT 或仅主机。

## 6. 快照、备份和迁移

- **基础快照**：装好系统和依赖后，关机并执行 `vmrun -T ws snapshot <vmx> base-clean`。
- **恢复**：`vmrun -T ws revertToSnapshot <vmx> base-clean`。
- **备份和迁移**：关机后复制整个虚拟机目录，并用 `Get-FileHash` 校验。在新电脑上打开时选择“我已移动该虚拟机”。

## 7. GPU 说明

VMware 的虚拟显卡不是物理 NVIDIA GPU。普通虚拟机**不支持 CUDA**，模板也没有此类配置。
