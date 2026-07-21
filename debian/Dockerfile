FROM scratch

# These archives are produced by the cDSO pipeline before the image build.
ADD tmp_home.tar.gz /
ADD packages.tgz /
ADD symlinks.tgz /
ADD identity.tgz /

WORKDIR /home/user
USER user
