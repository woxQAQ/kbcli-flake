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
        }.${system} or (throw "Unsupported system: ${system}, supported systems are: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin");

        # 構建預期的文件名
        expectedName = "kbcli-${platform.os}-${platform.arch}-v${version}.tar.gz";

        # 從 release assets 中找到對應的資源
        binaryAsset = pkgs.lib.findFirst 
          (asset: asset.name == expectedName)
          (throw "No binary found for ${expectedName} in release ${version}")
          latestRelease.assets;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "kbcli";
          inherit version;

          src = pkgs.fetchurl {
            url = binaryAsset.browser_download_url;
            sha256 = "sha256-cY9wjFF9efIIpew+5s4T/PoqwPnFKD9hweijYKRQtqA=";
          };

          nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];

          unpackPhase = ''
            echo "Unpacking archive..."
            tar xzvf $src
            echo "Contents of current directory:"
            ls -la
          '';

          installPhase = ''
            echo "Contents before install:"
            ls -la
            echo "Creating bin directory..."
            mkdir -p $out/bin
            echo "Finding kbcli binary..."
            find . -name kbcli -type f -exec ls -l {} \;
            echo "Installing kbcli..."
            find . -name kbcli -type f -exec install -m755 {} $out/bin/kbcli \;
          '';

          meta = with pkgs.lib; {
            description = "The CLI for KubeBlocks";
            homepage = "https://github.com/apecloud/kbcli";
            license = licenses.agpl3Only;
            maintainers = with maintainers; [ ];
            mainProgram = "kbcli";
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          };
        };

        packages.kbcli = self.packages.${system}.default;
      }
    );
} 