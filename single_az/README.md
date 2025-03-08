# terraform-sandbox - single_az

The single_az code creates all the resources needed to deploy a simple publically accessible EC2 instance. 

- The instance is created with a small root volume. 
- The instance is created with an additional "user" EBS volume. 

The root volume is very samll which is fine for throwaway demonstration instance. It's useful to understand how to update the infrastructure-as-code definition to resize the device and then resize the filesystem.

The user volume isn't currently automatically formatted and mounted but this would be simple to add using cloud init user data or a similar mechanism. In order to understand how disk sizing and changes work, we can format, label and mount the second block device, change it and observe the corresponding in-instance behaviour.



## Growing the root volume online
Growing an AWS EBS volume with Terraform is fairly simple. If no `root_block_device` configuration is included for the `aws_instance` definition in the Terraform HCL, the default size for ami-0eb11ab33f229b26c is 8GB. 

This is equivalent to:

```
resource "aws_instance" "public_bastions" {
    ...
    root_block_device {
        volume_size = 8
    }
    ...
}
```

1. Increase the root volume size:

    resource "aws_instance" "public_bastions" {
    ...
    root_block_device {
        volume_size = 16
    }
    ...
    }
    ```

2. Run `terraform plan` / `terraform apply`

    ```
    wmcdonald@fedora single_az ±|main ✗|→ terraform apply -auto-approve
    aws_vpc.main: Refreshing state... [id=vpc-0367eff39661a89dd]

    Terraform will perform the following actions:

    # aws_instance.public_bastions[0] will be updated in-place
    ~ resource "aws_instance" "public_bastions" {
            id                 = "i-0c3bd43a8c917d0d9"
            tags                                 = {
                "InstanceName" = "bastion-0"
                "InstanceRole" = "bastion"
                "Name"         = "bastion-0"
            }
            # (39 unchanged attributes hidden)

        ~ root_block_device {
                tags            = {}
            ~ volume_size       = 8 -> 16
                # (9 unchanged attributes hidden)
            }

            # (8 unchanged blocks hidden)
        }

    Plan: 0 to add, 1 to change, 0 to destroy.
    aws_instance.public_bastions[0]: Modifications complete after 32s [id=i-0c3bd43a8c917d0d9]

    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
    ```

3. Resize the partition the root filesystem (`/`) is placed on

    ```
    root@ip-10-0-1-26:~# df -h /
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/xvda1      7.7G  837M  6.5G  12% /

    root@ip-10-0-1-26:~# growpart /dev/xvda 1
    CHANGED: partition=1 start=262144 old: size=16513024 end=16775167 new: size=33292255 end=33554398
    ```

4. Resize the root filesystem

    ```
    root@ip-10-0-1-26:~# resize2fs /dev/xvda1
    resize2fs 1.47.0 (5-Feb-2023)
    Filesystem at /dev/xvda1 is mounted on /; on-line resizing required
    old_desc_blocks = 1, new_desc_blocks = 2
    The filesystem on /dev/xvda1 is now 4161531 (4k) blocks long.
    ```

5. Check that the filesystem has grown

    ```
    root@ip-10-0-1-26:~# df -h /
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/xvda1       16G  837M   14G   6% /
    ```

## Formatting, labelling and mounting the user volume

1. Connect to the new instance

2. List the disks
    ```
    root@ip-10-0-1-73:~# fdisk -l | grep '^Disk /dev'
    Disk /dev/xvda: 8 GiB, 8589934592 bytes, 16777216 sectors
    Disk /dev/xvdb: 10 GiB, 10737418240 bytes, 20971520 sectors
    ```

3. Format and label the second block device

    ```
    root@ip-10-0-1-73:~# mkfs.ext4 -L /data /dev/xvdb 
    mke2fs 1.47.0 (5-Feb-2023)
    Creating filesystem with 2621440 4k blocks and 655360 inodes
    Filesystem UUID: caca7aef-2a89-4c9c-aa9d-0c415468b6f8
    Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

    Allocating group tables: done                            
    Writing inode tables: done                            
    Creating journal (16384 blocks): done
    Writing superblocks and filesystem accounting information: done 
    ```

4. Grab the UUID from the `blkid` output for the device

    ```
    root@ip-10-0-1-73:~# blkid /dev/xvdb 
    /dev/xvdb: LABEL="/data" UUID="caca7aef-2a89-4c9c-aa9d-0c415468b6f8" BLOCK_SIZE="4096" TYPE="ext4"
    ```

5. Create the `/data` mount point

    ```
    root@ip-10-0-1-73:~# mkdir /data
    ```

5. Add to the `fstab`

    ```
    root@ip-10-0-1-73:~# cat /etc/fstab
    # /etc/fstab: static file system information
    UUID=08244b87-a72e-44b0-9536-c2b6010094e0 / ext4 rw,discard,errors=remount-ro,x-systemd.growfs 0 1
    UUID=5EF0-0F4E /boot/efi vfat defaults 0 0
    UUID=caca7aef-2a89-4c9c-aa9d-0c415468b6f8 /data ext4 rw,discard,errors=remount-ro,x-systemd.growfs 0 1
    ```

5. Reload systemd

    ```
    root@ip-10-0-1-73:~# systemctl daemon-reload 
    ```

5. Mount the device

    ```
    root@ip-10-0-1-73:~# mount /data
    ```

6. Validate the mount point state

    ```
    root@ip-10-0-1-73:~# df -h -t ext4
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/xvda1      7.7G  837M  6.5G  12% /
    /dev/xvdb       9.8G   24K  9.3G   1% /data
    ```

## Resizing the user volume with a reboot
1. Create some persistent state before resizing

    ```
    root@ip-10-0-1-73:~# echo "Persistent state test" > /data/state
    root@ip-10-0-1-73:~# ls -l /data/state 
    -rw-r--r-- 1 root root 22 Mar  7 22:04 /data/state
    root@ip-10-0-1-73:~# cat /data/state 
    Persistent state test
    ```

2. Resize the extra use volume, update ~./single_az/main.tf`:

    ```
    ##  user volume
    resource "aws_ebs_volume" "public_bastions_user_volumes" {
        count             = length(aws_instance.public_bastions)
        availability_zone = var.multi_azs[count.index]
        size              = 20
        type              = "gp3"
        tags = {
            InstanceName    = "bastion-${count.index}"
            VolumeName      = "user-volume-${count.index}"
            VolumePurpose   = "user-volume"
        }
    }
    ```

3. Apply the updated infrastructure-as-code:

    ```
    wmcdonald@fedora single_az ±|main ✗|→ terraform apply -auto-approve
    ```

4. Review the block device state from inside the EC2 instance

    ```
    root@ip-10-0-1-73:~# fdisk -l | grep '^Disk /dev'
    Disk /dev/xvda: 8 GiB, 8589934592 bytes, 16777216 sectors
    Disk /dev/xvdb: 20 GiB, 21474836480 bytes, 41943040 sectors

    root@ip-10-0-1-73:~# df -h /data/
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/xvdb       9.8G   28K  9.3G   1% /data
    ```

5. The block device resize is reflected inside the instance without restart, the filesystem is still pre-resize (this is expected). 

    If we reboot the system, `x-systemd.growfs` will detect the delta between filesystem and block device and grow the filesystem accordingly:

    ```
    root@ip-10-0-1-73:~# systemctl reboot 

    wmcdonald@fedora ~ → ssh -ladmin 34.243.242.121

    admin@ip-10-0-1-73:~$ sudo su -

    root@ip-10-0-1-73:~# df -h /data/
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/xvdb        20G   28K   19G   1% /data
    ```

    We could achieve the same result without a restart with `resize2fs`.
    
6. Validate that the persistent state we created is still present:

    ```
    root@ip-10-0-1-73:~# cat /data/state 
    Persistent state test
    ```