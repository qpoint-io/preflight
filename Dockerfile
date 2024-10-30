FROM mcr.microsoft.com/devcontainers/base:bookworm

RUN apt-get update && apt-get install -y curl wget shellcheck