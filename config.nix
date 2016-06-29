{ pkgs }:

{
  allowUnfree = true;
  allowBroken = true;
  packageOverrides = pkgs: with pkgs; rec {
    workstationEnv = buildEnv {
      name = "workstation-environment";
      paths = [ screen gitMinimal tig ack zsh irssi macvim ];
    };

    rubyEnv = stdenv.mkDerivation {
      name = "rubyEnv";
      buildInputs = [
        ruby libiconv libxml2 libxslt
        darwin.apple_sdk.frameworks.CoreServices darwin.libobjc
      ];
      shellHook = ''
        export GEM_HOME=$out
        export PATH=$GEM_HOME/bin:$PATH
      '';
    };

    chefEnv = stdenv.mkDerivation {
      name = "chefEnv";
      buildInputs = [
        ruby_2_1 libiconv libxml2 libxslt
        darwin.apple_sdk.frameworks.CoreServices darwin.libobjc];
      shellHook = ''
        export GEM_HOME=$out
        export PATH=$GEM_HOME/bin:$PATH
      '';
    };

    plistService = callPackage ./plist.nix {};

    jenkinsService = callPackage ./jenkins.nix {};
    aptCacherService = plistService {
      name = "apt-cacher-ng";
      programArgs = [
        "${apt-cacher-ng}/sbin/apt-cacher-ng" "-c"
        "/usr/local/etc/apt-cacher-ng"
        "foreground=1"
      ];
    };
    dnsmasqService = plistService {
      name = "dnsmasq";
      programArgs = [
        "${dnsmasq}/bin/dnsmasq" "--keep-in-foreground"
        "-C" "/usr/local/etc/dnsmasq.conf"
      ];
    };

    nexusService = plistService {
      name = "nexus";
      workingDirectory = nexus.out;
      programArgs = [
        "java"
        "-Dnexus-work=/usr/local/var/nexus"
        "-Dnexus-webapp-context-path=/"
        "-cp" "${nexus}/conf/:${nexus}/lib/*"
        "org.sonatype.nexus.bootstrap.Launcher"
        "${nexus}/conf/jetty.xml"
        "${nexus}/conf/jetty-requestlog.xml"
      ];
    };

    deisEnv = callPackage ./deis.nix { inherit (pythonPackages) pyyaml; };

    ecsCli = stdenv.mkDerivation {
      name = "ecs-cli-0.2.1";
      src = fetchurl {
        url = "https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-darwin-amd64-v0.2.1";
        sha256 = "12yrqan7ilxsxplmmbii7n2vpzwa0c6phfhbw0rl6xgn3zmisxhf";
      };

      buildCommand = ''
        mkdir -p $out/bin
        cp -v $src $out/bin/ecs-cli
        chmod 755 $out/bin/ecs-cli
      '';
    };

    dockerEnv = callPackage ./docker.nix { };

    terraform = stdenv.mkDerivation {
      name = "terraform-0.6.16";
      src = fetchurl {
        url = "https://releases.hashicorp.com/terraform/0.6.16/terraform_0.6.16_darwin_amd64.zip";
        sha256 = "0rlkvb2mrm2s9ilp990ql68ncvv2rl0cc0wa2bk7fs0jcf9bgzi3";
      };

      buildInputs = [ unzip ];

      buildCommand = ''
        mkdir -p $out/bin
        unzip $src -d $out/bin
      '';
    };

    nexus3 = stdenv.mkDerivation {
      name = "nexus-3.0.0-03";
      src = fetchurl {
        url = "http://download.sonatype.com/nexus/3/nexus-3.0.0-03-unix.tar.gz";
        sha256 = "1jnh6qcfdywp19yzawjzg41nsaaskbaj5kjwh8haa062zyg7crh6";
      };

      buildCommand = ''
        mkdir -p $out
        tar -xvzf $src --strip-components=1 -C $out
        substituteInPlace $out/bin/nexus.vmoptions \
            --replace "-Dkaraf.data=data" "-Dkaraf.data=/usr/local/var/nexus3" \
            --replace "-Djava.io.tmpdir=data/tmp" "-Djava.io.tmpdir=/usr/local/var/tmp/nexus3"
        substituteInPlace $out/etc/org.sonatype.nexus.cfg \
            --replace "application-port=8081" "application-port=18081"
      '';
    };

    revealjs = stdenv.mkDerivation {
      name = "revealjs-3.3.0";
      src = fetchurl {
        url = "https://github.com/hakimel/reveal.js/archive/3.3.0.tar.gz";
        sha256 = "0b3jyn91h8cacx8yirzxdw0nyyp1wk7zf28qz6h2i7hd2dpdqvm3";
      };

      buildCommand = ''
        mkdir -p $out
        tar -xvzf $src --strip-components=1 -C $out
      '';
    };

    google-cloud-sdk = stdenv.mkDerivation {
      name = "google-cloud-sdk-110.0.0";
      src = fetchurl {
        url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-110.0.0-darwin-x86_64.tar.gz";
        sha256 = "0fpz2dvs8by1pycf1q5lnwh0k5q7d29ilzb9wnzmx8kgq2716nh4";
      };

      buildCommand = ''
        tar -xzf $src --strip-components=1
        mkdir -p $out
        cp -rfv bin $out/bin
        cp -rfv lib $out/lib
      '';
    };

    packer = stdenv.mkDerivation {
      name = "packer.10.1";
      src = fetchurl {
        url =  "https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_darwin_amd64.zip";
        sha256 = "10gilh3mriqby132w0ifsmd8jj19vbgwi094wnxhqgxl3yzj3ips";
      };

      buildInputs = [ unzip ];

      buildCommand = ''
        mkdir -p $out/bin
        cd $out/bin
        unzip $src
      '';
    };

    kubernetes = stdenv.mkDerivation {
      name = "kubernetes-1.2.4";
      src = fetchurl {
        url = "https://storage.googleapis.com/kubernetes-release/release/v1.2.4/bin/darwin/amd64/kubectl";
        sha256 = "0a2979zcbz7qhw6k0x13x1c2zxvdkiryskryva99n17y676zi44m";
      };

      buildCommand = ''
        mkdir -p $out/bin
        cp -fv $src $out/bin/kubectl
        chmod 755 $out/bin/kubectl
      '';
    };
  };
}
