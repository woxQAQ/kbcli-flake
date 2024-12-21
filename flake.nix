{
  description = "kbcli - The CLI for KubeBlocks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # 獲取最新版本信息
        latestRelease = builtins.fromJSON (builtins.readFile (pkgs.fetchurl {
          url = "https://api.github.com/repos/apecloud/kbcli/releases/latest";
          sha256 = "sha256-iJEz9qh6LgZdDlc4RD7H9Sc/yqHxEpE6+mxFs449bCo=";
        }));
        
        version = builtins.substring 1 (builtins.stringLength latestRelease.tag_name) latestRelease.tag_name;

        # 根據系統選擇正確的平台標識
        platform = {
          x86_64-linux = { os = "linux"; arch = "amd64"; };
          aarch64-linux = { os = "linux"; arch = "arm64"; };
          x86_64-darwin = { os = "darwin"; arch = "amd64"; };
          aarch64-darwin = { os = "darwin"; arch = "arm64"; };
        }.${system} or (throw "Unsupported system: ${system}");

        # 構建預期的文件名
        expectedName = "kbcli-${platform.os}-${platform.arch}-v${version}.tar.gz";

        # 從 release assets 中找到對應的資源
        binaryAsset = pkgs.lib.findFirst 
          (asset: asset.name == expectedName)
          (throw "No binary found for ${expectedName}")
          latestRelease.assets;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "kbcli";
          inherit version;

          src = pkgs.fetchurl {
            url = binaryAsset.browser_download_url;
            sha256 = "sha256-cY9wjFF9efIIpew+5s4T/PoqwPnFKD9hweijYKRQtqA="; # 首次運行會提示正確的 hash 值
          };

          dontUnpack = true;

          installPhase = ''
            mkdir -p $out/bin
            tar xzf $src
            cp $src $out/bin/kbcli
            chmod +x $out/bin/kbcli
          '';

          meta = with pkgs.lib; {
            description = "The CLI for KubeBlocks";
            homepage = "https://github.com/apecloud/kbcli";
            license = licenses.agpl3Only;
            maintainers = with maintainers; [ ];
            mainProgram = "kbcli";
          };
        };

        packages.kbcli = self.packages.${system}.default;
      }
    );
} 