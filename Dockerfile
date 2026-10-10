ARG TARGETARCH
FROM --platform=linux/amd64 nixpkgs/nix-flakes:latest-x86_64-linux AS nix-amd64
FROM --platform=linux/arm64 nixpkgs/nix-flakes:latest-aarch64-linux AS nix-arm64
FROM nix-${TARGETARCH} AS dev

WORKDIR /workspace

COPY flake.nix flake.lock ./
RUN git config --global --add safe.directory /workspace \
    && nix develop --no-update-lock-file --command true

ENTRYPOINT ["nix", "develop", "--no-update-lock-file", "--command"]
CMD ["bash"]
