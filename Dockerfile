FROM bitnami/minideb:stretch
RUN install_packages jq moreutils
ADD https://storage.googleapis.com/kubernetes-release/release/v1.12.9/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl
ADD * /
RUN chmod +x /*.sh
CMD ["/run.sh"]