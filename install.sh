#!/bin/bash
set -e
set -o pipefail

trap 'echo "❌ Failed at line $LINENO"; exit 1' ERR

echo "🔥 Seismic Devnet Installer for Linux/WSL"
cd ~

# 1. Install Rust if not exists
if ! command -v rustc &>/dev/null; then
  echo "🦀 Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# 2. Load Rust environment
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
else
  echo "❌ Rust not installed properly. Missing ~/.cargo/env"
  exit 1
fi

export PATH="$HOME/.cargo/bin:$PATH"

# 3. Install jq
if ! command -v jq &>/dev/null; then
  echo "🔧 Installing jq..."
  sudo apt update && sudo apt install -y jq
fi

# 4. Install sfoundryup
echo "🚀 Installing sfoundryup..."
curl -L https://raw.githubusercontent.com/SeismicSystems/seismic-foundry/seismic/sfoundryup/install -o install_sfoundryup.sh
chmod +x install_sfoundryup.sh
bash install_sfoundryup.sh

export PATH="$HOME/.config/.seismic/bin:$PATH"

# 5. Build Seismic Foundry tools
echo "🔨 Building sfoundry (scast, sforge, sanvil)..."
source "$HOME/.cargo/env"
sfoundryup

# 6. Clone try-devnet
if [ ! -d "try-devnet" ]; then
  echo "📥 Cloning try-devnet..."
  git clone --recurse-submodules https://github.com/SeismicSystems/try-devnet.git
else
  echo "🔁 Updating try-devnet..."
  cd try-devnet && git pull && git submodule update --init --recursive && cd ..
fi

# 7. Deploy smart contract
echo "🚀 Deploying contract..."
cd try-devnet/packages/contract/
bash script/deploy.sh
cd ~

# 8. Install Bun
if ! command -v bun &>/dev/null; then
  echo "🍞 Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# 9. Run transact script
echo "📡 Running transact.sh..."
cd ~/try-devnet/packages/cli/
bun install
bash script/transact.sh

echo "✅ DONE: Seismic Devnet setup & deploy complete!"
