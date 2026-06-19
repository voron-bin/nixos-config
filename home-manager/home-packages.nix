{ pkgs, ... }: {
	nixpkgs.config.allowUnfree = true;

	home.packages = with pkgs; [
		# sort packages in categories to make it easy to find
		# here are all the packages that should be shared across systems
		# ============================================================
		# SYSTEM KERNEL & FIRMWARE (Handled by boot.kernelPackages)
		# ============================================================
		linux-firmware        # Essential for hardware support
		# Note: 'linux' is handled via boot.kernelPackages = pkgs.linuxPackages_zen;
		# Note: 'linux-headers' are auto-generated when installing the kernel

		# ============================================================
		# GRAPHICS & DISPLAY (HYPRLAND ECOSYSTEM)
		# ============================================================
		hyprland
		hyprlock
		hyprpicker
		hyprpolkitagent       # Required for Polkit dialogs in Hyprland
		hyprshot
		kitty
		rofi
		starship
		zsh
		awww

		# ============================================================
		# BROWSERS & WEB APPLICATIONS
		# ============================================================
		mullvad-browser
		freetube
		
		# ============================================================
		# OFFICE & PRODUCTIVITY
		# ============================================================
		libreoffice
		gnucash
		inkscape
		librecad
		nextcloud-client
		mullvad-vpn           # Use 'mullvad-vpn' (removed '-bin')

		# ============================================================
		# MEDIA & AUDIO/VIDEO
		# ============================================================
		vlc
		spotify               # Use 'spotify' from nixpkgs (unstable) or flatpak
		pipewire
		wireplumber
		alsa-utils            # Low-level ALSA tools
				
		# ============================================================
		# TERMINAL & CLI TOOLS
		# ============================================================
		btop                  # System monitor
		fastfetch
		ranger
		man-db                # Manual pages
		inotify-tools         # For ashell triggers
		rsync
		stress
		git                   # Version control
		python3               # Python interpreter (includes pip)

		# ============================================================
		# FONTS & THEMES
		# ============================================================
		font-awesome          # Check 'otf-font-awesome' or 'ttf-font-awesome'
		terminus_font
		nerd-fonts.jetbrains-mono  # Nerdfont version of JetBrains Mono
		ubuntu-sans
		nerd-fonts.ubuntu
		ultimate-oldschool-pc-font-pack
		papirus-icon-theme
		papirus-folders

		# ============================================================
		# NETWORKING & SECURITY
		# ============================================================
		networkmanager
		fwupd
		nmap

		# ============================================================
		# HARDWARE SUPPORT
		# ============================================================
		android-tools         # ADB/Fastboot
		brightnessctl
		rocmPackages.rocm-smi          # AMD GPU monitoring
		solaar
		smartmontools
		xf86-video-amdgpu     # Often optional on Wayland but good to have
		
		# ============================================================
		# PRINTING
		# ============================================================
		cups
		cups-pdf-to-pdf
		gutenprint
		
		# ============================================================
		# FILE MANAGEMENT & UTILITIES
		# ============================================================
		gvfs                  # Includes gphoto2, mtp, smb backends
		pcmanfm
		p7zip                 # Nix package name for 7zip
		unzip
		zip
		ntfs3g
		exfatprogs

		# ============================================================
		# SESSION & UI
		# ============================================================
		greetd
		tuigreet              # The package name is usually part of greetd-tuigreet
		mako                  # Notification daemon

		# ============================================================
		# PDF & DOCUMENTS
		# ============================================================
		zathura
		zathuraPkgs.zathura_pdf_mupdf

		# ============================================================
		# MISC / DEVELOPMENT
		# ============================================================
		texliveFull		# Full TeX Live suite (replaces multiple texlive-* packages)
		# java21-openjfx        # Java with FX
		# jdk17                 # Eclipse Temurin JDK 17
		# jdk21                 # OpenJDK 21
		# tk                    # Tcl/Tk
		# unrar                 # RAR extraction
		# wget                  # Standard download tool
		# curl                  # HTTP tool
	];
}
