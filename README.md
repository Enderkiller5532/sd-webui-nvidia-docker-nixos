# sd-webui-nvidia-docker-nixos
Docker image with Forge WebUI and full NVIDIA Blackwell (RTX 50xx) support. Includes docker-compose, desktop entry, and a NixOS user configuration helper.

 This image is made for NixOS users to install Forge WebUI with Docker.

# Attention please
NO ROOT USER OR SUDO (Except ```sudo {nano/vim/neovim/etc} /etc/nixos/configuration.nix``` and if you are in ```docker``` group)

# Installation      

#### Preparation for all methods.

```
mkdir -p "$HOME/ai/forge/models/checkpoints"
mkdir -p "$HOME/ai/forge/models/loras"
cd "$HOME/ai/forge"
mkdir -p "$(pwd)/mnt/outputs"
```

### Method 1. (No cloning repo)
Using the docker run command. The current image name is ```enderkiller5532/forge-webui-nvidia:latest``` or if stable build ```enderkiller5532/forge-webui-nvidia:2026.1.cu128-ser50```


First, you must run this command to create a container (it will return an error; this is expected).

```
docker run \
  --name stable-diffusion-forge \
  --device nvidia.com/gpu=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  -p 7860:7860 \
  -v "$(pwd)/mnt/outputs:/mnt/outputs" \
  -v "$HOME/ai/forge/models/checkpoints:/app/forge/models/Stable-diffusion" \
  -v "$HOME/ai/forge/models/loras:/app/forge/models/Lora" \
  --shm-size=8g \
  forge-web-ui-nvidia:latest
```

Then you can use:
```
docker start stable-diffusion-forge # or use (-d) if you don't want to see logs and keep the terminal active
```
## In this part, you can change location of checkpoints and loras. I use it to connect forge to comfy. 
Now i use this in ```~/ai #folder``` , so if you need to connect it to comfy. 

Here is an example of my config.
```
  -v "$HOME/ai/ComfyUI/models/checkpoints:/app/forge/models/Stable-diffusion" 
  -v "$HOME/ai/ComfyUI/models/loras:/app/forge/models/Lora" 
```

### Method 2. Clone repo and self build (recommended)


```
git clone https://github.com/Enderkiller5532/sd-webui-nvidia-docker-nixos.git "$HOME/ai/sd-webui-nvidia-docker-nixos"
cd "$HOME/ai/sd-webui-nvidia-docker-nixos"
```
Edit the docker-compose as you like it.
```
version: '3.8'
services:
  forge-ui:
    build: .
    container_name: stable-diffusion-forge
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
    ports:
      - "7860:7860"
    volumes:
      - ./mnt/outputs:/mnt/outputs
      - ~/ai/forge/models/checkpoints:/app/forge/models/Stable-diffusion
      - ~/ai/forge/models/loras:/app/forge/models/Lora
    # NixOS GPU - not only for nixos
    devices:
      - nvidia.com/gpu=all
    shm_size: '8gb'
```
Now run :
```
docker-compose up -d # you will get an error
docker-compose up -d # after first startup it will run normal
```
After the error, you will have docker-compose container,and question how start it like an app.

Answer: use desktop entry.
Copy it to your 
```
cp WebUI.desktop "$HOME/Desktop" 
```
  or if hyprland NixOS
```
cp WebUI.desktop "$HOME/.local/share/applications"
```
For new users {it will make app icon in app managers like rofi or gnome app search}


# For NixOS users

Enable Docker and NVIDIA Container Toolkit
```

    virtualisation.docker.enable = true;  
    virtualisation.docker.daemon.settings = {
            data-root = "/mnt/docker";
        };
    hardware.nvidia-container-toolkit.enable = true;

```
## Driver Section (Careful) [Wiki](https://wiki.nixos.org/wiki/NVIDIA)
All settings for the graphics card. RTX 50xx series config (Not for laptop) (Skip if installed) 

```
        # Enable opengl new version 
      hardware.graphics = {
        enable = true;
      };
            # for xserver set drivers
      services.xserver.videoDrivers = [
              "nvidia"
           ];
            # enable proprietary drivers 
    nixpkgs.config.nvidia.acceptLicense = true;
  
                # Driver config 
   hardware.nvidia = {
        open = true; # Compatible with RTX 2080 Super and newer
        nvidiaSettings = true; # GUI tool for NVIDIA settings (Wayland does not work correctly)
        modesetting.enable = true; # Wayland support , DON'T TOUCH (hyprland and wayland users).
        #powerManagement.enable = true;
        powerManagement.finegrained = false;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  
    boot = {
      kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_modeset" "nvidia_drm" "i915" ];
      initrd.kernelModules = [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      kernelParams = [ "nvidia-drm.modeset=1" ]; # Optimize 
   };
```

Firewall
```
   networking.firewall = {
     enable = true;
     allowedTCPPorts = [ 7860 ];
#    allowedUDPPorts = [      ];
   };
```
# TL;DR
First try return an error - - don't care about it.Second start container,just copy paste,and dont rush and be careful with Nixos Driver section.
```
mkdir -p "$HOME/ai/forge/models/checkpoints"
mkdir -p "$HOME/ai/forge/models/loras"
cd "$HOME/ai/forge"
mkdir -p "$(pwd)/mnt/outputs
git clone https://github.com/Enderkiller5532/sd-webui-nvidia-docker-nixos.git "$HOME/ai/sd-webui-nvidia-docker-nixos"
cd "$HOME/ai/sd-webui-nvidia-docker-nixos"
docker-compose up -d
```
```
docker-compose up -d
```

Author: Enderkiller5532 (Ilkin Rasulov)