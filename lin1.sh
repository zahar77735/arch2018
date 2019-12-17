#!/bin/bash

# Arch Linux Fast Install - Быстрая установка Arch Linux https://github.com/ordanax/arch2018
# Цель скрипта - быстрое развертывание системы с вашими персональными настройками (конфиг XFCE, темы, программы и т.д.).

# В разработке принимали участие:
# Алексей Бойко https://vk.com/ordanax
# Степан Скрябин https://vk.com/zurg3
# Михаил Сарвилин https://vk.com/michael170707
# Данил Антошкин https://vk.com/danil.antoshkin
# Юрий Порунцов https://vk.com/poruncov

loadkeys ru
setfont cyr-sun16
echo 'Скрипт сделан на основе чеклиста Бойко Алексея по Установке ArchLinux'
echo 'Ссылка на чек лист есть в группе vk.com/arch4u'

echo '2.3 Синхронизация системных часов'
timedatectl set-ntp true

pacman -S btrfs-progs zsh arch-install-scripts --noconfirm

echo '2.4 создание разделов'

echo 'Ваша разметка диска'
lsblk

read -p "Выбор диска: " devsection
cfdisk /dev/$devsection

read -p "Выбор swap раздела: " swapsection
mkswap /dev/$swapsection -L swap
swapon /dev/$swapsection

read -p "Выбор системного раздела: " rootsection


echo '2.4.2 Форматирование диска'
mkfs.btrfs -L "root" /dev/$rootsection

echo '2.4.3 Монтирование диска'
mount /dev/$rootsection /mnt

echo '2.4.4 Создание подтомов'
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume list /mnt
umount /mnt
mount -o subvol=@,compress=lzo,relatime,space_cache,autodefrag /dev/$rootsection /mnt
mkdir /mnt/home
mount -o subvol=@home,compress=lzo,relatime,space_cache,autodefrag /dev/$rootsection /mnt/home

echo '3.1 Выбор зеркал для загрузки. Ставим зеркало от Яндекс'
echo "Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

echo '3.2 Установка основных пакетов'
pacstrap /mnt base base-devel linux linux-firmware nano dhcpcd netctl btrfs-progs os-prober wget grub zsh mc

echo '3.3 Настройка системы'
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/zsh

read -p "Введите имя компьютера: " hostname
read -p "Введите имя пользователя: " username

echo 'Прописываем имя компьютера'
echo $hostname > /etc/hostname
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

echo '3.4 Добавляем русскую локаль системы'
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 

echo 'Обновим текущую локаль системы'
locale-gen

echo 'Указываем язык системы'
echo 'LANG="ru_RU.UTF-8"' >> /etc/locale.conf
echo 'LC_MESSAGES="ru_RU.UTF-8"' >> /etc/locale.conf

echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

nano /etc/mkinitcpio.conf

echo 'Создадим загрузочный RAM диск'
mkinitcpio -p linux

echo '3.5 Устанавливаем загрузчик'

grub-install /dev/$devsection

echo 'Обновляем grub.cfg'
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Ставим программу для Wi-fi'
pacman -S dialog wpa_supplicant --noconfirm 

echo 'Добавляем пользователя'
useradd -m -g users -G wheel,audio,video,storage -s /bin/zsh $username

echo 'Создаем root пароль'
passwd

echo 'Устанавливаем пароль пользователя'
passwd $username

echo 'Устанавливаем SUDO'
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

echo 'Раскомментируем репозиторий multilib Для работы 32-битных приложений в 64-битной системе.'
echo '[multilib]' >> /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
pacman-key --init
pacman-key --populate archlinux
pacman -Syy

echo "Куда устанавливем Arch Linux на виртуальную машину?"
read -p "1 - Да, 0 - Нет: " vm_setting
if [[ $vm_setting == 0 ]]; then
  gui_install="xorg-server xorg-drivers xorg-xinit"
elif [[ $vm_setting == 1 ]]; then
  gui_install="xorg-server xorg-drivers xorg-xinit virtualbox-guest-utils"
fi

echo 'Ставим иксы и драйвера'
pacman -S $gui_install

echo "Какое DE ставим?"
read -p "1 - XFCE, 2 - KDE, 3 - Gnome: " vm_setting
if [[ $vm_setting == 1 ]]; then
  pacman -S xfce4 xfce4-goodies lightdm --noconfirm
  systemctl enable lightdm
elif [[ $vm_setting == 2 ]]; then
  pacman -Sy plasma-meta kdebase kdm --noconfirm
  systemctl enable kdm
elif [[ $vm_setting == 3 ]]; then  
  pacman -S gnome gnome-shell gdm --noconfirm
  ssystemctl enable gdm
fi


echo 'Ставим шрифты'
pacman -S ttf-liberation ttf-dejavu --noconfirm 

echo 'Ставим сеть'
pacman -S networkmanager network-manager-applet ppp --noconfirm

echo 'Подключаем автозагрузку менеджера входа и интернет'
systemctl enable NetworkManager

echo 'Установка завершена! Перезагрузите систему.'

exit
reboot
