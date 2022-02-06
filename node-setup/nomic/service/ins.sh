# install rustup if you haven't already
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# nomic currently requires rust nightly
rustup default nightly

# clone
git clone https://github.com/nomic-io/nomic.git nomic && cd nomic

# build and install, adding a `nomic` command to your PATH
cargo install --path .