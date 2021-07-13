{ lib, writeText, runCommand, writeReferencesToFile }:

let
  currentSystemSplit = lib.splitString "-" builtins.currentSystem;
  currentOS = lib.last currentSystemSplit;
  currentArch = lib.head currentSystemSplit;
in
{
  buildContainer =
    { args
    , mounts ? {}
    , os ? currentOS
    , arch ? currentArch
    , readonly ? false
    , extraOciConfig ? {}
    }:
  let
    sysMounts = {
      "/proc" = {
        type = "proc";
        source = "proc";
      };
      "/dev" = {
        type = "tmpfs";
        source = "tmpfs";
        options = [ "nosuid" "strictatime" "mode=755" "size=65536k" ];
      };
      "/dev/pts" = {
        type = "devpts";
        source = "devpts";
        options = [ "nosuid" "noexec" "newinstance" "ptmxmode=0666" "mode=755" "gid=5" ];
      };
      "/dev/shm" = {
        type = "tmpfs";
        source = "shm";
        options = [ "nosuid" "noexec" "nodev" "mode=1777" "size=65536k" ];
      };
      "/dev/mqueue" = {
        type = "mqueue";
        source = "mqueue";
        options = [ "nosuid" "noexec" "nodev" ];
      };
      "/sys" = {
        type = "sysfs";
        source = "sysfs";
        options = [ "nosuid" "noexec" "nodev" "ro" ];
      };
      "/sys/fs/cgroup" = {
        type = "cgroup";
        source = "cgroup";
        options = [ "nosuid" "noexec" "nodev" "relatime" "ro" ];
      };
    };
    merged = lib.recursiveUpdate {
      ociVersion = "1.0.0";
      platform = {
        inherit os arch;
      };

      linux = {
        namespaces = map (type: { inherit type; }) [ "pid" "network" "mount" "ipc" "uts" ];
      };

      root = { path = "rootfs"; inherit readonly; };

      process = {
        inherit args;
        user = { uid = 0; gid = 0; };
        cwd = "/";
      };

      mounts = lib.mapAttrsToList (destination: { type, source, options ? null }: {
        inherit destination type source options;
      }) sysMounts;
    } extraOciConfig;
    config = writeText "config.json" (builtins.toJSON merged);
  in
    runCommand "oci-image" {} ''
      set -o pipefail
      mkdir -p $out/rootfs/{dev,proc,sys}
      cp ${config} $out/config.json
      xargs tar c < ${writeReferencesToFile args} | tar -xC $out/rootfs/
    '';
}

